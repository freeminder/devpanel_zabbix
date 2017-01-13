class ItemsController < ApplicationController

  def index
    # get hosts' ids
    @hosts_arr = Array.new
    ZBX.query({"method": "host.get", "params": { "output": "extend" }}).each do |host|
      @hosts_arr << Hash[ "hostid" => host["hostid"], "host" => host["host"]]
    end

    # # get check_mem_diskspace_usage item id. will be useful to exclude it from array of common items.
    # @check_mem_diskspace_usage_item_ids = Array.new
    # @hostids_arr.each do |hostid|
    #   @check_mem_diskspace_usage_item_ids << Hash[ "hostid" => hostid, "check_mem_diskspace_usage_item_id" => ZBX.query(
    #     {
    #       "method": "item.get",
    #       "params": {
    #         "output": "extend",
    #         "hostids": hostid,
    #         "search": {
    #             "key_": "check_mem_diskspace_usage"
    #         },
    #       },
    #     }
    #   ).first["itemid"]]
    # end


    # # generate array with items
    # @items_arr = Array.new
    # @hosts_arr.each do |hostid|
    #   @items_arr << ZBX.query(
    #     {
    #       "method": "item.get",
    #       "params": {
    #         "output": "extend",
    #         "hostids": hostid["hostid"],
    #       },
    #     }
    #   )
    # end

    # # generate array and get the history for every item
    # @items_history_arr = Array.new
    # # cleanup array from empty elements
    # @items_arr.delete_if { |item| item.empty? }
    # @items_arr.each do |item|
    #   @items_history_arr << ZBX.query(
    #     "method": "history.get",
    #     "params": {
    #         "output": "extend",
    #         # "timefrom": params[:timefrom],
    #         "itemids": item["itemid"],
    #         "sortfield": "clock",
    #         "sortorder": "DESC",
    #         "limit": 10
    #     },
    #   )
    # end

    # # update array with items names
    # @items_history_arr.delete_if { |items| items.empty? }
    # @items_history_arr.each do |items|
    #   # items.delete_if { |item| item.empty? }
    #   items.each do |item|
    #     item["name"] = ZBX.query(
    #       "method": "item.get",
    #       "params": {
    #         "output": "extend",
    #         "itemids": item["itemid"],
    #       },
    #     )["name"]
    #   end
    # end

  end

  def show
    @host = ZBX.query(
      {
        "method": "host.get",
        "params": {
          "output": "extend",
          "hostids": params[:id],
        },
      }
    ).first

    @items = ZBX.query(
      {
        "method": "item.get",
        "params": {
          "output": "extend",
          "hostids": params[:id],
        },
      }
    )

  end

  # def new
  # end

  # def create
  # end

end
