
RELAYFQDN="RELAYFQDN"
RELAYPORT="52311"
RELAYREGISTRATION="OneTimeRegistration"
INSTALLER="BESAgent.rpm"

# Set base folder
INSTALLDIR="."

if [ ! -f $INSTALLDIR/clientsettings.cfg ] ; then
  # create clientsettings.cfg file
  echo -n > $INSTALLDIR/clientsettings.cfg
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_RelaySelect_FailoverRelay=https://$RELAYFQDN:$RELAYPORT/bfmirror/downloads/
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_SecureRegistration=$RELAYREGISTRATION
  >> $INSTALLDIR/clientsettings.cfg echo __RelaySelect_Automatic=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_StartupNormalSpeed=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_RetryMinutes=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_CheckAvailabilitySeconds=120
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_WorkIdle=20
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_SleepIdle=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_PowerSaveEnable=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Query_SleepTime=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Query_WorkTime=250
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Query_NMOMaxQueryTime=30
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_AccelerateForPendingMessage=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Comm_CommandPollEnable=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Comm_CommandPollIntervalSeconds=1800
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Log_Days=30
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Log_MaxSize=1536000
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_UtilitiesCacheLimitMB=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_DownloadsCacheLimitMB=5000
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_MinimumDiskFreeMB=2000
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_ActionManager_HistoryKeepDays=1825
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_ActionManager_HistoryDisplayDaysTech=90
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_ActionManager_CompletionDialogTimeoutSeconds=30
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_PersistentConnection_Enabled=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_ActionManager_OverrideTimeoutSeconds=21600
fi

if [ ! -f $INSTALLDIR/masthead.afxm ] ; then
    echo ERROR: need masthead file in same folder
    exit 2
fi

# MUST HAVE ROOT PRIV
if [ "$(id -u)" != "0" ]; then
  echo
  echo "Sorry, you are not root. Exiting."
  echo
  exit 1
fi

############################################################
###    Start execution:    #################################
############################################################

# define function to check for commands:
command_exists () {
  type "$1" &> /dev/null ;
}

# install BigFix client
if [[ $INSTALLER == *.deb ]]; then
  #  debian (DEB)
  set -e
  dpkg -i $INSTALLER
fi
if [[ $INSTALLER == *.pkg ]]; then
  # PKG type
  #   Could be Mac OS X, Solaris, or AIX
  if command_exists installer ; then
    #  Mac OS X
    set -e
    installer -pkg $INSTALLER -target /
  else
    if command_exists pkgadd ; then
        #  Solaris
        set -e
        echo y | pkgadd -d $INSTALLER BESagent
    fi # pkgadd
  fi # installer
fi # *.pkg install file
if [[ $INSTALLER == *.rpm ]]; then
  #  linux (RPM)
  set -e
  # if file `/etc/init.d/besclient` exists then do upgrade
  if [ -f /etc/init.d/besclient ]; then
    /etc/init.d/besclient stop
    rpm -U $INSTALLER
  else
    rpm -ivh $INSTALLER
  fi
fi

### start the BigFix client (required for most linux dist)
# if file `/etc/init.d/besclient` exists
if [ -f /etc/init.d/besclient ]; then
  # if missing, create besclient.config file based upon /tmp/clientsettings.cfg
  if [ ! -f /var/opt/BESClient/besclient.config ]; then
    cat $INSTALLDIR/clientsettings.cfg | awk 'BEGIN { print "[Software\\BigFix\\EnterpriseClient]"; print "EnterpriseClientFolder = /opt/BESClient"; print; print "[Software\\BigFix\\EnterpriseClient\\GlobalOptions]"; print "StoragePath = /var/opt/BESClient"; print "LibPath = /opt/BESClient/BESLib"; } /=/ {gsub(/=/, " "); print "\n[Software\\BigFix\\EnterpriseClient\\Settings\\Client\\" $1 "]\nvalue = " $2;}' > /var/opt/BESClient/besclient.config
    chmod 600 /var/opt/BESClient/besclient.config
  fi

  # Do not start bigfix if: StartBigFix=false
  if [[ "$StartBigFix" != "false" ]]; then
    /etc/init.d/besclient start
  fi
fi

echo BigFix should be installed and started:
echo use the following command to examine logs:
echo tail --verbose "/var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log"
