FROM centos:centos6
# Based on Bernardo Gomez Palacio <bernardo.gomezpalacio@gmail.com> work to add
# some useful items I like to have.
#
# Original:
# 	* https://github.com/berngp/docker-zabbix
#
MAINTAINER Oisin Mulvihill <oisin.mulvihill@gmail.com>

# Update base images.
RUN yum distribution-synchronization -y

# Install EPEL, MySQL, Zabbix release packages.
RUN yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum install -y http://repo.zabbix.com/zabbix/2.2/rhel/6/x86_64/zabbix-release-2.2-1.el6.noarch.rpm

RUN yum makecache
# Installing SNMP Utils
#RUN yum -y install libsnmp-dev libsnmp-base libsnmp-dev libsnmp-perl libnet-snmp-perl librrds-perl
RUN yum -y -q install net-snmp-devel net-snmp-libs net-snmp net-snmp-perl net-snmp-python net-snmp-utils
# Install Lamp Stack, including PHP5 SNMP
RUN yum -y -q install mysql mysql-server
# Install Apache and PHP5
RUN yum -y -q install httpd php php-mysql php-snmp
# Additional Tools
RUN yum -y -q install passwd perl-JSON pwgen vim
# Install packages.
RUN yum -y -q install java-1.7.0-openjdk
# Install zabbix server and php frontend
RUN yum -y -q install zabbix-agent zabbix-get zabbix-java-gateway zabbix-sender zabbix-server zabbix-server-mysql zabbix-web zabbix-web-mysql
# Install database files, please not version number in the package (!)
RUN yum -y -q install zabbix22-dbfiles-mysql
# install monit
RUN yum -y -q install monit
# Get the mkpasswd utility i use later:
# Reference:
#  * http://pikedom.com/?p=74
#
RUN yum -y install expect
# SSHd to aid debugging if exposed.
# Reference:
#    http://www.cyberciti.biz/faq/centos-ssh/
#
RUN yum -y -q install openssh-server openssh-clients
# enable the service and run it
RUN chkconfig sshd on
RUN service sshd start
#-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT

# Cleaining up.
RUN yum clean all
# helper tools for python
RUN yum -y -q install python-pip
# Requests in externalscripts really helps make web scripts much simpler.
# Reference:
#  * http://www.cyberciti.biz/faq/debian-ubuntu-centos-rhel-linux-install-pipclient/
RUN pip install requests
# MySQL
ADD ./mysql/my.cnf /etc/mysql/conf.d/my.cnf
# Zabbix Conf Files
ADD ./zabbix/zabbix.ini 				/etc/php.d/zabbix.ini
ADD ./zabbix/httpd_zabbix.conf  		/etc/httpd/conf.d/zabbix.conf
ADD ./zabbix/zabbix.conf.php    		/etc/zabbix/web/zabbix.conf.php
ADD ./zabbix/zabbix_agentd.conf 		/etc/zabbix/zabbix_agentd.conf
ADD ./zabbix/zabbix_java_gateway.conf 	/etc/zabbix/zabbix_java_gateway.conf
ADD ./zabbix/zabbix_server.conf 		/etc/zabbix/zabbix_server.conf

RUN chmod 640 /etc/zabbix/zabbix_server.conf
RUN chown root:zabbix /etc/zabbix/zabbix_server.conf

# Monit
ADD ./monitrc /etc/monitrc
RUN chmod 600 /etc/monitrc

# https://github.com/dotcloud/docker/issues/1240#issuecomment-21807183
RUN echo "NETWORKING=yes" > /etc/sysconfig/network

# Add the script that will start the repo.
ADD ./scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Expose the Ports used by
# * Zabbix services
# * Apache with Zabbix UI
# * Monit
EXPOSE 10051 10052 80 22 2812

# Make a directory scripts (alert, externalchecks, etc could use)
RUN mkdir /logs

# Add a user to aid problem diagnosis if SSHd is exposed.
RUN groupadd admin
RUN useradd -g admin -g admin -s /bin/bash -m -d /home/admin admin
# shinken is the password for shinken user to aid debugging issues over ssh.
RUN usermod -p $(mkpasswd -H md5 adminaccess) admin
# Generate ssh keys
RUN su - admin -c 'ssh-keygen -q -f /home/admin/.ssh/id_rsa -N ""'


VOLUME ["/var/lib/mysql", "/usr/lib/zabbix/alertscripts", "/usr/lib/zabbix/externalscripts", "/etc/zabbix/zabbix_agentd.d", "/logs"]
CMD ["/bin/bash", "/start.sh"]
