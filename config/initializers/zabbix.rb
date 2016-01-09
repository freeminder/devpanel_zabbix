require "zabbixapi"

# auth
ZBX = ZabbixApi.connect(
  :url => ENV['ZBX_URL'],
  :user => ENV['ZBX_USER'],
  :password => ENV['ZBX_PASSWORD']
)
