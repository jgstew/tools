#!/usr/bin/env bash
#
# This script, when run on a host with Docker installed, will run an ubuntu/centos container and install the BigFix client
#
# replace `alpha.bigfix.com` with your own BigFix root server or relay
sudo docker run -d ubuntu bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh alpha.bigfix.com;tail -f /dev/null"

sudo docker run -it centos bash -c "yum install initscripts -y;cd /tmp;curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh alpha.bigfix.com;tail -f /dev/null"

# http://stackoverflow.com/questions/30209776/docker-container-will-automatically-stop-after-docker-run-d
# http://stackoverflow.com/a/33497697/861745

# http://serverfault.com/questions/442088/how-do-you-answer-yes-for-yum-install-automatically
# https://github.com/docker-library/official-images/issues/339
# https://forum.bigfix.com/t/problem-install-besclient-on-centos7-docker-image-initscripts/18128
