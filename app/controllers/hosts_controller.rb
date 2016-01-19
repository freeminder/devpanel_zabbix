class HostsController < ApplicationController
  before_filter :grab_data, except: [:new, :create, :edit, :update, :destroy]


  def grab_data
    # generate array with hosts info
    @host_generic_info = ZBX.query(
      method: "host.get",
      params: {
        "output": "extend"
      }
    )

    # generate array with hostids
    @hostids = Array.new
    @host_generic_info.each { |host| @hostids << host["hostid"] }

    # generate array with interfaces data
    @host_interface_info = ZBX.query(
      "method": "hostinterface.get",
      "params": {
        "output": "extend",
        "hostids": @hostids
      }
    )

    # generate array of interfaces with associated hostids and internal hosts
    @hosts_arr = Array.new
    @host_interface_info.each do |int|
      @host_generic_info.each do |host|
        if int["hostid"] == host["hostid"]
          @hosts_arr << Hash[id: host["hostid"], name: host["name"], ip: int["ip"], dns: int["dns"], port: int["port"], useip: int["useip"]]
        end
      end
    end
  end

  def index
  end

  def show
    if params[:id] != '' and params[:id] != 'index' and params[:id] != 'new' and params[:id] != 'edit'
      @host = @hosts_arr.select { |v| v[:id] =~ /#{params[:id]}/ }.first

      # template info
      @template_info = ZBX.query(
        "method": "template.get",
        "params": {
          "output": "extend",
          "hostids": @host[:id]
        }
      )

      @host[:template_name] = @template_info.first["name"]
      @host[:template_id]   = @template_info.first["templateid"]

      # hostgroup info
      @hostgroup_info = ZBX.query(
        "method": "hostgroup.get",
        "params": {
          "output": "extend",
          "hostids": @host[:id]
        }
      )

      @host[:hostgroup_name] = @hostgroup_info.first["name"]
      @host[:hostgroup_id]   = @hostgroup_info.first["groupid"]

      # graph info
      @host_graphs_output = ZBX.query(
        method: "graph.get",
        params: {
          "output": "extend",
          "hostids": @host[:id],
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
      render 'show'
    else
      puts "condition_catched!"
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
      host_id = ZBX.query(
        method: "host.create",
        params: {
          "host":  params[:host][:name],
          "interfaces": [
            {
              "type":  1,
              "main":  1,
              "ip":    params[:host][:ip],
              "dns":   params[:host][:dns],
              "port":  params[:host][:port],
              "useip": params[:host][:useip]
            }
          ],
          "groups": [
            {
              "groupid": '2'
            }
          ],
          "templates":[
            {
              "templateid": '10001'
            }
          ]
        }
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

