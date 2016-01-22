class TeamsController < ApplicationController

  before_filter :authorize_admin


  def index
    @teams = Team.all
    @users = User.all
  end

  def show
    @users = User.all
    @team_id = params[:id].to_i
    @team = Team.find(@team_id)
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(team_params)
    @teams = Team.all
    if @team.save
      flash[:success] = "Team has been successfully created!"
      redirect_to @team
    else
      render 'new'
    end
  end

  def edit
    @team = Team.find(params[:id])
  end

  def update
    @team = Team.find(params[:id])
    if @team.update_attributes(team_params)
      respond_to do |format|
        format.any { redirect_to :back, notice: 'Team has been successfully updated!' }
      end
    else
      respond_to do |format|
        format.any { render action: 'edit' }
      end
    end
  end

  def destroy
    @team = Team.find(params[:id])
    if @team.destroy
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:notice] = 'Team has been successfully deleted!'
      end
    else
      respond_to do |format|
        format.any { render action: 'edit' }
      end
    end
  end

private

  def team_params
    params.require(:team).permit(:name)
  end


end
