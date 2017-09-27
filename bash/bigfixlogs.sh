
# this IF could be better, but this should mostly work:
if [ -d "/Library/Application Support/Bigfix/BES Agent/__BESData/__Global/Logs" ]; then
  LogFolder="/Library/Application Support/Bigfix/BES Agent/__BESData/__Global/Logs"
else
  LogFolder="/var/opt/BESClient/__BESData/__Global/Logs"
fi

ls $LogFolder

# /var/opt/BESClient/__BESData/__Global/Logs
# /Library/Application Support/Bigfix/BES Agent/__BESData/__Global/Logs
# https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli+Endpoint+Manager/page/Common+File+Locations
