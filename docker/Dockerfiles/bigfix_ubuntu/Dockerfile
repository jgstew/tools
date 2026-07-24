
############################################################
# WORK IN PROGRESS
#  currently must replace _PUT.YOUR.RELAY.HERE.hostnameORfqdnORip_ below
# Run the BigFix Client on Ubuntu
#  - https://github.com/jgstew/tools/blob/master/bash/docker_bigfix_client.sh
# docker run -d -P --init bigfix_ubuntu
############################################################

FROM ubuntu:latest

RUN apt-get update
RUN apt-get install wget -y
RUN wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh

RUN StartBigFix=false bash install_bigfix.sh _PUT.YOUR.RELAY.HERE.hostnameORfqdnORip_

# start bigfix client when container is started
# using `exec sleep infinity` to keep it running: lighter than `tail -f /dev/null`
#  and exec lets SIGTERM from `docker stop` end the container promptly
# see the issue this solves:  https://github.com/jgstew/tools/issues/22
# NOTE: `sleep infinity` is GNU coreutils; on BusyBox/Alpine use `sleep 2147483647` instead
# could potentially use QnA to keep it running instead, which would be interesting
ENTRYPOINT ["/bin/bash","-c","/etc/init.d/besclient start; exec sleep infinity"]
