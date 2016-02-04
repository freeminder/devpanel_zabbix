#!/bin/bash

IFS=!
ARRAY=(`find /home/* -type d -links 2 -printf %f!`)

for username in ${ARRAY[*]}; do
  # mem usage
  IFS=$'\n'
  RSS_ARR=(`ps -u $username orss,cmd|grep -v RSS|awk '{print $1}'`)
  mem=$( awk 'BEGIN {t=0; for (i in ARGV) t+=ARGV[i]; print t}' ${RSS_ARR[@]} )
  procs=${#RSS_ARR[@]}

  # disk space usage
  user_diskspace_usage=`du -s /home/${username}/|awk '{print $1}'`

  # db space usage
  db_size=`du -s /var/lib/mysql/${username}/|awk '{print $1}'`

  echo "$username,$(((user_diskspace_usage + db_size) / 1024)),$((mem / 1024)),$procs"
done
