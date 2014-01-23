#!/bin/bash

# create sandbox
SANDBOX=sandbox_$RANDOM
cd /tmp
mkdir $SANDBOX
cd $SANDBOX

# test resources
# check memory
# free, vmstat, top

# check disk
# df -h

# check network
# iostat, iotop, netstat

# clean environment ie un- and re-install apache and mysql
# stop services
service apache2 stop
service mysql stop

# uninstall
apt-get -q -y remove apache2
apt-get -q -y remove mysql-client mysql-server
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password Z debconf-set-selections

# update apt repo
apt-get update

# reinstall
apt-get -q -y install apache2
apt-get -q -y install mysql-client mysql-server

# restart services
service apache2 start
service mysql start

# untar app
tar -zcxf webpackage_preDeploy.tgz DeploymentWebApp

# move components to /www and /cgi-bin
cp ~/DeploymentWebApp/www/* /var/www
cp ~/DeploymentWebApp/cgi-bin/* /etc/cgi-bin/

# test necessary files are in place
DEPINDEX="/var/www/index.html"
DEPAFPL="/etc/cgi-bin/accept_form.pl"
DEPHW="/etc/cgi-bin/hello_world.pl"
DEPTDB="etc/cgi-bin/testdb.pl"
if [ -e "$DEPINDEX" ] && [ -e "$DEPAFPL" ] && [ -e "$DEPHW" ] && [ -e "$DEPTDB" ]
then
	echo "All files in place"
else
	echo "Files not in place, exiting..."
	exit
fi

# configure crontab to run monitoring script
# modified from http://stackoverflow.com/questions/610839/how-can-i-programatically-create-a-new-cron-job
# configure crontab, make sure new cron job is unique

(crontab -l ; echo "* * * * * ~/logmon.sh") | uniq - | crontab -
