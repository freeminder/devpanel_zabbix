#!/bin/bash -e

if [ "$UID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Only run it if we can (ie. on Ubuntu/Debian)
if [ -x /usr/bin/apt-get ]; then
  apt-get update
  apt-get -y install zabbix-agent sysv-rc-conf
  sysv-rc-conf zabbix-agent on
  sed -i 's/Server=127.0.0.1/Server=52.90.49.206/' /etc/zabbix/zabbix_agentd.conf
  sed -i 's/ServerActive=127.0.0.1/ServerActive=52.90.49.206/' /etc/zabbix/zabbix_agentd.conf
  sed -i 's/# EnableRemoteCommands=0/EnableRemoteCommands=1/' /etc/zabbix/zabbix_agentd.conf
  HOSTNAME=`hostname` && sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
  # patch sudoers and avoid duplicates
  if [ `grep -Fxq "zabbix ALL=NOPASSWD" /etc/sudoers` ]; then
    echo "zabbix ALL=NOPASSWD: /opt/webenabled/sbin/check_mem_diskspace_usage.sh" >> /etc/sudoers
  else
    sed -i 's/^zabbix\ ALL=NOPASSWD.*//g' /etc/sudoers
    echo "zabbix ALL=NOPASSWD: /opt/webenabled/sbin/check_mem_diskspace_usage.sh" >> /etc/sudoers
  fi

  service zabbix-agent restart
fi

# Only run it if we can (ie. on RHEL/CentOS)
if [ -x /usr/bin/yum ]; then
  yum -y update
  rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm
  yum -y install zabbix-agent
  chkconfig zabbix-agent on
  sed -i 's/Server=127.0.0.1/Server=52.90.49.206/' /etc/zabbix/zabbix_agentd.conf
  sed -i 's/ServerActive=127.0.0.1/ServerActive=52.90.49.206/' /etc/zabbix/zabbix_agentd.conf
  sed -i 's/# EnableRemoteCommands=0/EnableRemoteCommands=1/' /etc/zabbix/zabbix_agentd.conf
  HOSTNAME=`hostname` && sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
  # patch sudoers and avoid duplicates
  if [ `grep -Fxq "zabbix ALL=NOPASSWD" /etc/sudoers` ]; then
    echo "zabbix ALL=NOPASSWD: /opt/webenabled/sbin/check_mem_diskspace_usage.sh" >> /etc/sudoers
  else
    sed -i 's/^zabbix\ ALL=NOPASSWD.*//g' /etc/sudoers
    echo "zabbix ALL=NOPASSWD: /opt/webenabled/sbin/check_mem_diskspace_usage.sh" >> /etc/sudoers
  fi

  service zabbix-agent restart
fi
