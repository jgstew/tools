
############################################################
# WORK IN PROGRESS - UNTESTED!
# Dockerfile to for LDAP testing
# Based on Ubuntu
# Managed with BigFix
############################################################

FROM ubuntu:latest

RUN apt-get update
RUN apt-get install wget -y
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd

# This password should be changed:
RUN echo 'root:thisisabadpassword' | chpasswd
# This is a bad idea, consider using a non-root user instead:
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# install ldap deamon
RUN bash -c "echo 'slapd slapd/password2 password thisisabadpassword' | debconf-set-selections && echo 'slapd slapd/password1 password thisisabadpassword' | debconf-set-selections && apt-get install -qq slapd"
RUN apt-get install -qq ldap-utils
RUN printenv > /tmp/env.txt

EXPOSE 22 80 443 389 636
CMD ["/usr/sbin/sshd", "-D"]

# https://docs.docker.com/engine/admin/multi-service_container/
