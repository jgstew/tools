#!/usr/bin/env bash

# this IF could be better, but this should mostly work:
if [ -d "/Library/Application Support/Bigfix/BES Agent/__BESData/__Global/Logs" ]; then
  LogFolder="/Library/Application Support/Bigfix/BES Agent/__BESData/__Global/Logs"
else
  LogFolder="/var/opt/BESClient/__BESData/__Global/Logs"
fi

LogFile="$LogFolder/`date +%Y%m%d`.log"

# Start of output:
echo "-------------------------------------------------------------------------------------"
echo "$LogFolder"
ls "$LogFolder"
echo "-------------------------------------------------------------------------------------"
# https://stackoverflow.com/questions/36989457/retrieve-last-100-lines-logs
# https://ss64.com/bash/tail.html
tail -n ${1:-25} "$LogFile"

# /var/opt/BESClient/__BESData/__Global/Logs
# /Library/Application Support/Bigfix/BES Agent/__BESData/__Global/Logs
# https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli+Endpoint+Manager/page/Common+File+Locations

