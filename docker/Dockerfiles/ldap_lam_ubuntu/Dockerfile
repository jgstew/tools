
############################################################
# WORK IN PROGRESS - UNTESTED!
# Usage, in empty dir, to create image:  sudo docker build -t "ldap_lam_ubuntu" .
# Usage, to run a container instance of this:  sudo docker run -d -P ldap_lam_ubuntu
# Dockerfile to for LDAP testing
# Based on Ubuntu
# TODO: manage with bigfix
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

# install ldap daemon
RUN bash -c "echo 'slapd slapd/password2 password thisisabadpassword' | debconf-set-selections && echo 'slapd slapd/password1 password thisisabadpassword' | debconf-set-selections && apt-get install -qq slapd"
#TODO: https://www.ldap-account-manager.org/static/doc/manual-onePage/index.html#a_installation
# RUN apt-get install -qq ldap-account-manager
RUN apt-get install -qq ldap-utils

# https://www.digitalocean.com/community/tutorials/how-to-manage-and-use-ldap-servers-with-openldap-utilities
# http://www.thegeekstuff.com/2015/02/openldap-add-users-groups
# https://docs.oracle.com/cd/E19424-01/820-4809/bcacw/index.html

# ldapsearch -H ldap://localhost -x -D "cn=admin,dc=nodomain" -W
# ldapsearch -H ldap:// -x -D "cn=admin,dc=nodomain" -W -b "dc=nodomain"

# dn: ou=bigfixadmins,dc=nodomain
# changetype: add
# objectclass: top
# objectClass: organizationalUnit
# ou: bigfixadmins

# dn: uid=bigfixtest,ou=bigfixadmins,dc=nodomain
# changetype: add
# objectclass: top
# objectclass: person
# objectclass: organizationalPerson
# uid: bigfixtest
# cn: bigfixtest
# userPassword: badpassword


# something for curiosity:
RUN printenv > /tmp/env.txt

EXPOSE 22 80 443 389 636
CMD ["/usr/sbin/sshd", "-D"]

# https://docs.docker.com/engine/admin/multi-service_container/
# https://github.com/tianon/docker-brew-ubuntu-core/issues/59

