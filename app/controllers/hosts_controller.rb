class HostsController < ApplicationController

  def index
    @hosts = Host.all

    info = ZBX.query(
      :method => "host.get",
      :params => { 
        "output": "extend" 
      }
    )

    # render :text => info
  end

  def show
    @host = Host.find(params[:id])
  end

  def new
    @host = Host.new
    @hostgroups = Hostgroup.all
  end

  def create
    @host = Host.new(host_params)
    if @host.save
      # add host
      host_id = ZBX.hosts.create_or_update(
        :host => params[:host][:name],
        :interfaces => [
          {
            :type => 1,
            :main => 1,
            :ip => params[:host][:ip],
            :dns => params[:host][:dns],
            :port => params[:host][:port],
            :useip => params[:host][:useip]
          }
        ],
        :groups => [ :groupid => ZBX.hostgroups.get_id(:name => "Linux servers") ]
      )
      @host.update_attributes(host_id: host_id)

      # show success popup
      flash[:success] = "Host has been successfully added!"
      # redirect and show host's info
      # redirect_to @host
      redirect_to controller: 'hosts', action: 'index'
    else
      render 'new'
    end
  end

  def edit
    @host = Host.find(params[:id])
  end

  def update
    @host = Host.find(params[:id])
    if @host.update_attributes(host_params)
      respond_to do |format|
        format.any { redirect_to :back, notice: 'Host has been successfully updated!' }
      end
    else
      respond_to do |format|
        format.any { render action: 'edit' }
      end
    end
  end

  def destroy
    @host = Host.find(params[:id])
    # Remove host first, while name exists in DB
    ZBX.hosts.delete ZBX.hosts.get_id(:host => @host.name)
    if @host.destroy
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:notice] = 'Host has been successfully removed!'
      end
    else
      respond_to do |format|
        format.any { render action: 'edit' }
      end
    end
  end

private

  def host_params
    params.require(:host).permit(:name, :hostgroup_id, :ip, :dns, :port, :useip)
  end

end


