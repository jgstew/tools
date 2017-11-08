
############################################################
# Dockerfile to for LDAP testing:  https://github.com/jgstew/tools/blob/master/docker/Dockerfiles/ldap_ubuntu/Dockerfile
# WORK IN PROGRESS - UNTESTED!
# Usage, in empty dir, to create image:  sudo docker build -t "ldap_ubuntu" .
# Usage, to run a container instance of this:  sudo docker run -d -P ldap_ubuntu
#
# Related: https://github.com/jgstew/tools/blob/master/docker/Dockerfiles/ldap_lam_ubuntu/Dockerfile
############################################################

FROM ubuntu:latest

RUN apt-get update && apt-get install -qq ldap-utils

# install ldap deamon
RUN bash -c "echo 'slapd slapd/password2 password thisisabadpassword' | debconf-set-selections && echo 'slapd slapd/password1 password thisisabadpassword' | debconf-set-selections && apt-get install -qq slapd"
#TODO: https://www.ldap-account-manager.org/static/doc/manual-onePage/index.html#a_installation
# RUN apt-get install -qq ldap-account-manager

# https://www.digitalocean.com/community/tutorials/how-to-manage-and-use-ldap-servers-with-openldap-utilities
# http://www.thegeekstuff.com/2015/02/openldap-add-users-groups
# https://docs.oracle.com/cd/E19424-01/820-4809/bcacw/index.html

# ldapsearch -H ldap://localhost -x -D "cn=admin,dc=nodomain" -W
# ldapsearch -H ldap:// -x -D "cn=admin,dc=nodomain" -W -b "dc=nodomain"

RUN service slapd start
EXPOSE 389 636
CMD ["/usr/bin/tail", "-f", "/dev/null"]
