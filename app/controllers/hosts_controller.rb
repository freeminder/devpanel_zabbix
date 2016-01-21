class HostsController < ApplicationController
  before_filter :grab_data, except: [:new, :create]
  before_filter :grab_additional_data, except: [:index, :show, :create, :update, :destroy]

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
          @hosts_arr << Hash[id: host["hostid"], name: host["name"], interfaceid: int["interfaceid"], ip: int["ip"], dns: int["dns"], port: int["port"], useip: int["useip"]]
        end
      end
    end

    # templates and hostgroups
    @hosts_arr.each do |host|
      ZBX.query(
        method: "template.get",
        params: {
          "output": "extend",
          "hostids": host[:id]
        }
      ).each do |template|
        host[:template_id]   = template["templateid"]
        host[:template_name] = template["name"]
      end

      ZBX.query(
        "method": "hostgroup.get",
        "params": {
          "output": "extend",
          "hostids": host[:id]
        }
      ).each do |hostgroup|
        host[:hostgroup_id]   = hostgroup["groupid"]
        host[:hostgroup_name] = hostgroup["name"]
      end
    end
  end

  def grab_additional_data
    # generate array with templates info
    @templates = ZBX.query(
      method: "template.get",
      params: {
        "output": "extend",
      },
    )

    # generate array with hostgroups info
    @hostgroups = ZBX.query(
      method: "hostgroup.get",
      params: {
        "output": "extend",
      },
    )
  end

  def index
  end

  def show
    if params[:id] == params[:id].to_i.to_s
      @host = @hosts_arr.select { |v| v[:id] =~ /#{params[:id]}/ }.first

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
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:error] = 'Wrong host id!'
      end
    end
  end

  def new
    @host = Host.new
  end

  def create
    if ZBX.query(
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
            "groupid": params[:host][:groupid]
          }
        ],
        "templates":[
          {
            "templateid": params[:host][:templateid]
          }
        ]
      }
    )['hostids']
      # show success popup
      flash[:notice] = "Host has been successfully added!"
      redirect_to controller: 'hosts', action: 'index'
    else
      render 'new'
    end
  end

  def edit
    if params[:id] == params[:id].to_i.to_s
      @host = @hosts_arr.select { |v| v[:id] =~ /#{params[:id]}/ }.first
    else
      # show error popup
      respond_to do |format|
        format.any { redirect_to action: 'show' }
        flash[:error] = 'Wrong host id!'
      end
    end
  end

  def update
    if params[:id] == params[:id].to_i.to_s
      @host = @hosts_arr.select { |v| v[:id] =~ /#{params[:id]}/ }.first

      # update name, template and hostgroup
      ZBX.query(
        method: "host.update",
        params: {
          "hostid": @host[:id],
          "host":      params[:host][:name],
          "name":      params[:host][:name],
          "groups": [
            {
              "groupid": params[:host][:groupid]
            }
          ],
          # Template's change causes items dependant errors
          # "templates":[
          #   {
          #     "templateid": params[:host][:templateid]
          #   }
          # ]
        }
      )

      # update hostinterface
      ZBX.query(
        method: "hostinterface.update",
        params: {
          "interfaceid": @host[:interfaceid],
          "ip":     params[:host][:ip],
          "dns":    params[:host][:dns],
          "port":   params[:host][:port],
          "useip":  params[:host][:useip]
        }
      )

      # show success popup
      respond_to do |format|
        format.any { redirect_to :back, notice: 'Host has been successfully updated!' }
      end
    else
      # show error popup
      respond_to do |format|
        format.any { redirect_to action: 'edit' }
        flash[:error] = 'Wrong host id!'
      end
    end
  end

  def destroy
    if params[:id] == params[:id].to_i.to_s
      @host = @hosts_arr.select { |v| v[:id] =~ /#{params[:id]}/ }.first

      ZBX.hosts.delete ZBX.hosts.get_id(:host => @host[:name])

      # show success popup
      respond_to do |format|
        format.any { redirect_to action: 'index' }
        flash[:notice] = 'Host has been successfully removed!'
      end
    else
      # show error popup
      respond_to do |format|
        format.any { redirect_to action: 'show' }
        flash[:error] = 'Wrong host id!'
      end
    end
  end

private

  def host_params
    params.require(:host).permit(:name, :hostgroup_id, :ip, :dns, :port, :useip)
  end

end

