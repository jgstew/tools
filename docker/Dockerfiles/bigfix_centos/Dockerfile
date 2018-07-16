
############################################################
# WORK IN PROGRESS
#  currently must replace _PUT.YOUR.RELAY.HERE.hostnameORfqdnORip_ below
# Run the BigFix Client on CentOS
#  - https://github.com/jgstew/tools/blob/master/bash/docker_bigfix_client.sh
# Make the container image:
#   docker build -f Dockerfile -t bigfix_centos_ROOTSERVER_ .
# docker run -d -P --init --restart=unless-stopped bigfix_centos_ROOTSERVER_
############################################################

FROM centos:latest

RUN yum install initscripts -y
RUN curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh

RUN StartBigFix=false bash install_bigfix.sh _PUT.YOUR.RELAY.HERE.hostnameORfqdnORip_

# start bigfix client when container is started
# using this to make it keep running:  tail -f /dev/null
# could potentially use QnA to keep it running instead, which would be interesting
ENTRYPOINT bash -c "/etc/init.d/besclient start;tail -f /dev/null"
