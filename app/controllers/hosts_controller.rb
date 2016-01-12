class HostsController < ApplicationController

  def index
    @hosts = Host.all
  end

  def show
    @host = Host.find(params[:id])
    @host_info_output = ZBX.query(
      method: "host.get",
      params: {
          "output": "extend",
          "filter": {
              "host": [
                  @host.name
              ]
          }
      }
    )
    @host_graphs_output = ZBX.query(
      method: "graph.get",
      params: {
          "output": "extend",
          "hostids": @host.host_id,
          "sortfield": "name"
      }
    )

    # init and auth Mechanize to grab the graphs
    @agent = Mechanize.new 
    @agent.get(ENV['ZBX_URL']) do |login_page|
      loggedin_page = login_page.form_with(:action => 'index.php') do |form|
        username_field = form.field_with(:id => 'name')
        username_field.value = ENV['ZBX_USER']
        password_field = form.field_with(:id => 'password')
        password_field.value = ENV['ZBX_PASSWORD']
      end.click_button
    end
    # remove old graphs if exists and grab new ones
    @host_graphs_output.each do |e|
      File.delete("#{Rails.root.to_s}/public/images/graph_#{e['graphid']}.png") if File.exist?("#{Rails.root.to_s}/public/images/graph_#{e['graphid']}.png")
      @agent.get("#{ENV['ZBX_URL']}/chart2.php?graphid=#{e['graphid']}").save "#{Rails.root.to_s}/public/images/graph_#{e['graphid']}.png"
    end
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


