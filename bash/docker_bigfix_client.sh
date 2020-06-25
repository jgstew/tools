#!/usr/bin/env bash
#
# This script, when run on a host with Docker installed, will run many different linux containers and install the BigFix client
#      Related: https://github.com/bigfix/bfdocker/tree/master/besclient


# if $1 exists, then set RELAYFQDN
# http://www.tldp.org/LDP/abs/html/comparison-ops.html
if [ -n "$1" ]; then
  RELAYFQDN=$1
else
  # You can replace `alpha.bigfix.com` with your own BigFix root server or relay
  RELAYFQDN=alpha.bigfix.com
fi

sudo docker run -d --restart=unless-stopped ubuntu bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
sudo docker run -d --restart=unless-stopped debian bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

sudo docker run -d --restart=unless-stopped centos bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
sudo docker run -d --restart=unless-stopped fedora bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

sudo docker run -d --restart=unless-stopped oraclelinux bash -c "cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

sudo docker run -d --restart=unless-stopped registry.access.redhat.com/rhel6 bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
sudo docker run -d --restart=unless-stopped registry.access.redhat.com/rhel7 bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
# sudo docker run -d --restart=unless-stopped registry.access.redhat.com/rhel8 bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"


# can't seem to get opensuse to work with the default docker image. missing some dependancies.
# sudo docker run -d opensuse bash -c "zypper --non-interactive install wget;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh alpha.bigfix.com;tail -f /dev/null"

# TODO: https://hub.docker.com/_/amazonlinux/

# http://stackoverflow.com/questions/30209776/docker-container-will-automatically-stop-after-docker-run-d
# http://stackoverflow.com/a/33497697/861745

# http://serverfault.com/questions/442088/how-do-you-answer-yes-for-yum-install-automatically
# https://github.com/docker-library/official-images/issues/339
# https://forum.bigfix.com/t/problem-install-besclient-on-centos7-docker-image-initscripts/18128
