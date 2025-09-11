#!/usr/bin/env bash
#
# This script, when run on a host with Docker installed, will run many different linux containers and install the BigFix client
#      Related: https://github.com/bigfix/bfdocker/tree/master/besclient

## See this: https://github.com/jgstew/tools/blob/master/bash/docker_list_tags.sh


# if $1 exists, then set RELAYFQDN
# http://www.tldp.org/LDP/abs/html/comparison-ops.html
if [ -n "$1" ]; then
  RELAYFQDN=$1
else
  # You can replace `root.fqdn.com` with your own BigFix root server or relay
  RELAYFQDN=bigfixrelay.fqdn.com
  echo provide a bigfix relay FQDN
  exit 2
fi

# sudo docker run -d --restart=unless-stopped ubuntu bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

wget -q https://registry.hub.docker.com/v1/repositories/ubuntu/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep -o "^[0-9]*\.[0-9]*" | uniq | while read -r line ; do
    echo "- Processing ubuntu:$line -"

    sudo docker run -d --restart=unless-stopped ubuntu:$line bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
done


# sudo docker run -d --restart=unless-stopped debian bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

wget -q https://registry.hub.docker.com/v1/repositories/debian/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep -o "^[0-9]*" | uniq  | while read -r line ; do
    echo "- Processing debian:$line -"

    sudo docker run -d --restart=unless-stopped debian:$line bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
done




# can't seem to get opensuse to work with the default docker image. missing some dependencies.
# sudo docker run -d opensuse bash -c "zypper --non-interactive install wget;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh alpha.bigfix.com;tail -f /dev/null"

# sudo docker run -d --restart=unless-stopped centos bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
# sudo docker run -d --restart=unless-stopped fedora bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

# sudo docker run -d --restart=unless-stopped oraclelinux bash -c "cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

# sudo docker run -d --restart=unless-stopped registry.access.redhat.com/rhel6 bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"
# sudo docker run -d --restart=unless-stopped registry.access.redhat.com/rhel7 bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh $RELAYFQDN;tail -f /dev/null"

# TODO: https://hub.docker.com/_/amazonlinux/

# http://stackoverflow.com/questions/30209776/docker-container-will-automatically-stop-after-docker-run-d
# http://stackoverflow.com/a/33497697/861745

# http://serverfault.com/questions/442088/how-do-you-answer-yes-for-yum-install-automatically
# https://github.com/docker-library/official-images/issues/339
# https://forum.bigfix.com/t/problem-install-besclient-on-centos7-docker-image-initscripts/18128
