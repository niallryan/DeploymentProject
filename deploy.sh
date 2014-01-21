#!/usr/bin/bash

SANDBOX=sandbox_$RANDOM
echo USING SANDBOX $SANDBOX

# stop apache
service apache2 stop

# stop mysql
service mysql stop

# remove current version of apache
apt-get -q -y remove apache2

# remove current version of mysql
apt-get -q -y remove mysql-client mysql-server
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password | debconf-set-selections

# refresh apt-get package repository
apt-get update

# clean reinstall of apache
apt-get -q -y install apache2

# clean reinstall of mysql
apt-get -q -y install mysql-client mysql-server

# create sandbox for web app
cd /tmp
mkdir $SANDBOX
cd $SANDBOX

# get web app from Git repo, put in sandbox
git clone https://github.com/niallryan/DeploymentWebApp.git

# move web app files to /cgi-bin and /www
cd DeploymentWebApp
cp www/* /var/www/
cp cgi-bin/* /usr/lib/cgi-bin/
chmod a+x /usr/lib/cgi-bin/*

# start apache
service apache2 start

# start mysql
service mysql start

# configure mysql
cat <<FINISH | mysql -uroot -ppassword
drop database if exists dbtest;
CREATE DATABASE dbtest;
GRANT ALL PRIVILEGES ON dbtest.* TO dbtestuser@localhost IDENTIFIED BY 'dbpassword';
use dbtest;
drop table if exists custdetails;
create table if not exists custdetails ( name VARCHAR(30) NOT NULL DEFAULT '', address VARCHAR(30) NOT NULL DEFAULT '' );
insert into custdetails (name,address) values ('Nicky Cahill', 'Carlow');
select * from custdetails;
FINISH

# remove sandbox
cd /tmp
rm -rf $SANDBOX

# check web app installed right
