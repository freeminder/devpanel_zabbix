class UsersController < ApplicationController

  before_filter :authorize_admin, except: [:show, :edit, :update]
  before_filter :grab_data, only: [:index, :show, :edit, :update, :destroy]
  before_filter :user_types, only: [:index, :show, :new, :edit]

  def grab_data
    # generate array with usermedias
    @usermedias_arr = ZBX.query(
      "method": "usermedia.get",
      "params": {
        "output": "extend",
      },
    )

    # extract emails to new array
    @useremails_arr = Array.new
    @usermedias_arr.each {|um| @useremails_arr << um["sendto"]}

    # generate array with Zabbix users
    @zbx_users_arr = ZBX.query(
      "method": "user.get",
      "params": {
        "output": "extend",
      },
    )
  end

  def user_types
    require 'ostruct'
    @types = Array.new
    @types << OpenStruct.new( id: 1, name: "Zabbix User" )
    @types << OpenStruct.new( id: 2, name: "Zabbix Admin" )
    @types << OpenStruct.new( id: 3, name: "Zabbix Super Admin" )
  end

  def index
    @users = User.all
  end

  def show
    # search for user type
    @zbx_users_arr.each do |u|
      @user_type = u["type"] if u["name"] == User.find(params[:id]).first_name and u["surname"] == User.find(params[:id]).last_name
    end

    # access control
    if current_user.admin?
      @user = User.find(params[:id])
      @team = Team.find(@user.team_id)
    else
      if current_user.id == params[:id].to_i
        @user = User.find(params[:id])
        @team = Team.find(@user.team_id)
      else
        redirect_to root_path, alert: 'Access Denied'
      end
    end
  end

  def new
    @user  = User.new
    @teams = Team.all
  end

  def create
    @user = User.new(user_params)
    @teams = Team.all
    if @user.save
      # remap internal group id with Zabbix:
      # params[:user][:team_id] = 1 if params[:user][:team_id] == 111
      # params[:user][:team_id] = 2 if params[:user][:team_id] == 222

      # sync user with Zabbix
      ZBX.query(
        "method": "user.create",
        "params": {
          "alias":   "#{params[:user][:first_name]} #{params[:user][:last_name]}",
          "name":    params[:user][:first_name],
          "surname": params[:user][:last_name],
          "type":    params[:user][:type_id],
          "passwd":  params[:user][:password],
          "usrgrps": [
            {
              # devPanel usergroup
              "usrgrpid": "13"
            }
          ],
          "user_medias": [
            {
              "mediatypeid": "1",
              "sendto": params[:user][:email],
              "active": 0,
              "severity": 63,
              "period": "1-7,00:00-24:00"
            }
          ]
        },
      )

      # show success popup
      flash[:notice] = "User has been successfully created and synced with Zabbix!"
      # redirect and show user's profile
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
    @teams = Team.all
  end

  def update
    @user = User.find(params[:id])

    # find user's id in Zabbix by email
    @usermedias_arr.each { |um| @zbx_user_id = um["userid"] if um["sendto"] == @user.email }

    if @user.update_attributes(user_params)

      # update user in Zabbix
      ZBX.query(
        "method": "user.update",
        "params": {
          "userid":  @zbx_user_id,
          "alias":   "#{params[:user][:first_name]} #{params[:user][:last_name]}",
          "name":    params[:user][:first_name],
          "surname": params[:user][:last_name],
          "type":    params[:user][:team_id],
        },
      )

      respond_to do |format|
        format.any { redirect_to :back, notice: 'User has been successfully updated in both internal DB and Zabbix!!' }
      end
    else
      respond_to do |format|
        format.any { render action: 'edit' }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])

    # find user's id in Zabbix by email
    @usermedias_arr.each { |um| @zbx_user_id = um["userid"] if um["sendto"] == @user.email }

    # remove user in Zabbix while he exists in DB
    ZBX.query(
      "method": "user.delete",
      "params": [
        {"userid": @zbx_user_id},
      ],
    )

    if @user.destroy
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:notice] = 'User has been successfully deleted from both internal DB and Zabbix!'
      end
    else
      respond_to do |format|
        format.any { render action: 'edit' }
      end
    end
  end

private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :team_id, :admin)
  end


end
