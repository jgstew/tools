
############################################################
# WORK IN PROGRESS
#  currently must replace _PUT.YOUR.RELAY.HERE.hostnameORfqdnORip_ below
# Run the BigFix Client on CentOS
#  - https://github.com/jgstew/tools/blob/master/bash/docker_bigfix_client.sh
# Make the container image:
#   docker build -f Dockerfile -t bigfix_centos_ROOTSERVER_ .
# Run it:
#   docker run -d -P --init --restart=unless-stopped bigfix_centos_ROOTSERVER_
# Run Many(10):
#   for i in {1..10}; do docker run -d -P --init --restart=unless-stopped bigfix_centos_ROOTSERVER_; done
############################################################

FROM centos:latest

RUN yum install initscripts -y
RUN curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh

RUN StartBigFix=false bash install_bigfix.sh _PUT.YOUR.RELAY.HERE.hostnameORfqdnORip_

# start bigfix client when container is started
# using `exec sleep infinity` to keep it running: lighter than `tail -f /dev/null`
#  and exec lets SIGTERM from `docker stop` end the container promptly
# see the issue this solves:  https://github.com/jgstew/tools/issues/22
# NOTE: `sleep infinity` is GNU coreutils; on BusyBox/Alpine use `sleep 2147483647` instead
# could potentially use QnA to keep it running instead, which would be interesting
ENTRYPOINT ["/bin/bash","-c","/etc/init.d/besclient start; exec sleep infinity"]
