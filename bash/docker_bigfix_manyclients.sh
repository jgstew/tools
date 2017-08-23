#!/usr/bin/env bash
#
# This script, when run on a host with Docker installed, will run many of the same linux containers and install the BigFix client
# The goal is to get the maximum number of clients running on a given set of hardware for load testing
# By default, 10 docker containers will be created
#      Related: https://github.com/bigfix/bfdocker/tree/master/besclient

# if $1 exists, then set RELAYFQDN
# http://www.tldp.org/LDP/abs/html/comparison-ops.html
if [ -n "$1" ]; then
  RELAYFQDN=$1
else
  # You can replace `alpha.bigfix.com` with your own BigFix root server or relay
  RELAYFQDN=alpha.bigfix.com
fi

# https://stackoverflow.com/a/169602/861745
# TODO make END settable as parameter
typeset -i i END
let END=10 i=1
while ((i<=END)); do

sudo docker run -d centos bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

  let i++
done # WHILE_END
