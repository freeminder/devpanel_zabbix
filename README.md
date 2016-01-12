# Zabbix API demo for devPanel

Based on [Ruby Zabbix Api Module](https://github.com/express42/zabbixapi)

This README would normally document whatever steps are necessary to get the application up and running.


## System dependencies

* Ruby version >= 2.0

* Nginx, Apache or similar web server

* [Phusion Passenger](https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/) or similar application server 

* SQLite

## Configuration

config/local_env.yml should exist and contain:

    # Zabbix auth
    ZBX_URL:       'url_of_zabbix_server'
    ZBX_USER:      'zabbix_api_user'
    ZBX_PASSWORD:  'zabbix_api_password'
    # secrets.yml
    SECRET_KEY_BASE: 'yoursecretkey'

## Installation

run in the devpanel_zabbix dir to install the dependencies:

    bundle install

## Database initialization

    rake db:migrate

## Deployment instructions

Upload devpanel_zabbix.tar.gz to the server, unpack it, change dir to devpanel_zabbix and run in the shell "touch tmp/restart.txt" - 
it will restart application server with the newest version of devpanel_zabbix.
Also there is configured Capistrano, so just change the configurations in config/deploy/*.rb with appropriate environment
and then deploy it via "cap staging deploy" or "cap production deploy".


## License

Please refer to [LICENSE](LICENSE).
