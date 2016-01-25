class ActionsController < ApplicationController
  before_filter :grab_data, except: [:new, :create]
  before_filter :grab_users_and_hosts, only: [:index, :show, :new]


  def grab_data
    # generate array with actions info
    @actions_arr = ZBX.query(
      "method": "action.get",
      "params": {
        "output": "extend",
        "selectOperations": "extend",
        "selectConditions": "extend",
      }
    )
  end

  def grab_users_and_hosts
    @users = ZBX.query(
        method: "user.get",
        params: {
          "output": "extend",
        }
    )

    @hosts = ZBX.query(
        method: "host.get",
        params: {
          "output": "extend",
        }
    )

    # associate users and hosts with its ids
    @actions_arr.each do |action|
      # set user attribute
      userid = action["operations"][0]["opmessage_usr"][0]["userid"] if action["operations"][0]["opmessage_usr"] and action["operations"][0]["opmessage_usr"][0]
      action["user"] = @users.detect {|user| user["userid"] == userid}["alias"] if userid
      # set host attribute
      hostid = action["conditions"][0]["value"] if action["conditions"] and action["conditions"][0] and action["conditions"][0]["value"]
      action["host"] = @hosts.detect {|host| host["hostid"] == hostid}["name"] if hostid and hostid.to_i.between?(10000, 99999)
    end
  end

  def index
  end

  def show
    if params[:id] == params[:id].to_i.to_s
      @action = @actions_arr.select { |v| v["actionid"] =~ /#{params[:id]}/ }.first

      render 'show'
    else
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:error] = 'Wrong action id!'
      end
    end
  end

  def new
  end

  def create
    if ZBX.query(
      "method": "action.create",
      "params": {
        "name": params[:name],
        "eventsource": 0,
        "evaltype": 0,
        "status": 0,
        "esc_period": 120,
        "def_shortdata": "{TRIGGER.NAME}: {TRIGGER.STATUS}",
        "def_longdata": "{TRIGGER.NAME}: {TRIGGER.STATUS}\r\nLast value: {ITEM.LASTVALUE}\r\n\r\n{TRIGGER.URL}",

        "recovery_msg": 1,
        "r_longdata": "{TRIGGER.NAME}: {TRIGGER.STATUS}",
        "r_shortdata": "{TRIGGER.NAME}: {TRIGGER.STATUS}\r\nLast value: {ITEM.LASTVALUE}\r\n\r\n{TRIGGER.URL}",

        "conditions": [
          {
            "conditiontype": 1,
            "operator": 0,
            "value": params[:hostid]
          },
        ],
        "operations": [
          {
            "operationtype": 0,
            "opmessage_usr": [
              {
                "userid": params[:userid]
              }
            ],
            "opmessage": {
              "default_msg": 1,
              "mediatypeid": "1"
            }
          },
        ]
      },
    )['actionids']
      # show success popup
      flash[:notice] = "Action has been successfully added!"
      redirect_to controller: 'actions', action: 'index'
    else
      render 'new'
    end
  end

  # def edit
  #   if params[:id] == params[:id].to_i.to_s
  #     @action = @actions_arr.select { |v| v["actionid"] =~ /#{params[:id]}/ }.first
  #   else
  #     # show error popup
  #     respond_to do |format|
  #       format.any { redirect_to action: 'show' }
  #       flash[:error] = 'Wrong action id!'
  #     end
  #   end
  # end

  # def update
  #   if params[:id] == params[:id].to_i.to_s
  #     @action = @actions_arr.select { |v| v["actionid"] =~ /#{params[:id]}/ }.first

  #     if ZBX.query(
  #       "method": "action.update",
  #       "params": {
  #           "actionid": params[:id],
  #       },
  #     )['actionids']

  #       # show success popup
  #       respond_to do |format|
  #         format.any { redirect_to :back, notice: 'Action has been successfully updated!' }
  #       end
  #     end
  #   else
  #     # show error popup
  #     respond_to do |format|
  #       format.any { redirect_to action: 'edit' }
  #       flash[:error] = 'Wrong action id!'
  #     end
  #   end
  # end

  def destroy
    if params[:id] == params[:id].to_i.to_s
      ZBX.query(
        "method": "action.delete",
        "params": [
          params[:id]
        ]
      )

      # show success popup
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:notice] = 'Action has been successfully removed!'
      end
    else
      # show error popup
      respond_to do |format|
        format.any { redirect_to action: 'show' }
        flash[:error] = 'Wrong action id!'
      end
    end
  end

end
