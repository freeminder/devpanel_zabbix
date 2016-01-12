require "zabbixapi"
require "mechanize"

# auth
ZBX = ZabbixApi.connect(
  :url => "#{ENV['ZBX_URL']}/api_jsonrpc.php",
  :user => ENV['ZBX_USER'],
  :password => ENV['ZBX_PASSWORD']
)
