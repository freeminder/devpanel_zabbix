class AppsController < ApplicationController

  def index
    # set hostid of demo server
    @hostid = "10113"

    # generate array with hosts
    @hosts = ZBX.query(
        method: "host.get",
        params: {
          "output": "extend",
        }
    )

    # generate array with hosts apps
    @apps_raw = ZBX.query(
      {
        "method": "item.get",
        "params": {
          "output": "extend",
          "hostids": @hostid,
          "search": {
              "key_": "check_mem_diskspace_usage"
          },
        },
      }
    ).first["lastvalue"].split("\n")

    # generate array with nested values
    @apps = Array.new
    @apps_raw.each do |app|
      @apps << app.split(',')
    end
  end

end
