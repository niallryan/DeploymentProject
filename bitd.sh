#!/bin/bash

cd /tmp

# create sandbox
SANDBOX=sandbox_$RANDOM
mkdir $SANDBOX
echo Using sandbox $SANDBOX
cd $SANDBOX

# set errorcheck variable to 0
ERRORCHECK=0

# create process folders
mkdir build
mkdir integrate
mkdir test

# get webpackage for testing
git clone https://github.com/niallryan/DeploymentWebApp.git

# tar up webpackage
tar -zcvf webpackage_preBuild.tgz DeploymentWebApp

# check if MD5sum has changed
MD5SUM=$(md5sum webpackage_preBuild.tgz | cut -f 1 -d' ')
PREVMD5SUM=$(cat /tmp/md5sum)
FILECHANGE=0
if [[ "$MD5SUM" != "$PREVMD5SUM" ]]
then
	FILECHANGE=1
	echo $MD5SUM not equal to $PREVMD5SUM
else
	FILECHANGE=0
	echo $MD5SUM equal to $PREVMD5SUM
fi

# store MD5sum out in file
echo $MD5SUM > /tmp/md5sum

# exit cleanly if MD5sum hasn't changed, otherwise proceed
if [ $FILECHANGE -eq 0 ]
then
	echo no change in files, doing nothing and exiting
	exit
fi

# move webpackage to build dir
mv webpackage_preBuild.tgz build
rm -rf DeploymentWebApp

# untar file
cd build
tar -zxvf webpackage_preBuild.tgz

# perform build/manipulation functions
# test form.html, accept_form.pl, hello_world.pl, testdb.pl exist
FORM="DeploymentWebApp/www/form.html"
if [ -e "$FORM" ]
then
	echo "form.html exists!"
else
	echo "form.html is not present!"
	ERRORCHECK=$((ERRORCHECK+1))
fi

ACCEPT_FORM="DeploymentWebApp/cgi-bin/accept_form.pl"
if [ -e "$ACCEPT_FORM" ]; then
	echo "accept_form.pl exists!"
else
	echo "accept_form.pl is not present!"
	ERRORCHECK=$((ERRORCHECK+1))
fi

HELLO="DeploymentWebApp/cgi-bin/hello_world.pl"
if [ -e "$HELLO" ]; then
	echo "hello_world.pl exists!"
else
	echo "hello_world.pl is not present!"
	ERRORCHECK=$((ERRORCHECK+1))
fi

TESTDB="DeploymentWebApp/cgi-bin/testdb.pl"
if [ -e "$TESTDB" ]; then
	echo "testdb.pl exists!"
else
	echo "testdb.pl is not present!"
	ERRORCHECK=$((ERRORCHECK+1))
fi

# integrate static html content from 2 or more files into 1
cat DeploymentWebApp/www/content.html DeploymentWebApp/www/image.html > DeploymentWebApp/www/index.html
INDEX="DeploymentWebApp/www/index.html"
if [ -e "$INDEX" ]
then
	echo "index.html created successfully"
else
	echo "index.html not created successfully"
	ERRORCHECK=$((ERRORCHECK+1))
fi

# clean environment (uninstall + reinstall apache + mysql)
# stop services
service apache2 stop
service mysql stop

# uninstall
apt-get -q -y remove apache2
apt-get -q -y remove mysql-client mysql-server
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password | debconf-set-selections

# refresh apt package repo
apt-get update

# reinstall
apt-get install apache2
apt-get install mysql-client mysql-server

# restart apache and mysql
service apache2 start
service mysql start

# tar package back up
tar -zcvf webpackage_preIntegrate.tgz DeploymentWebApp

# # move webpackage to Integrate dir and clean up
mv webpackage_preIntegrate.tgz ../integrate
rm -rf DeploymentWebApp

# untar
cd ../integrate
tar -zxvf webpackage_preIntegrate.tgz

# move html files to apache /www
cd DeploymentWebApp
cp www/* /var/www

# move perl files to /cgi-bin
cp cgi-bin/* /usr/lib/cgi-bin

# make perl files executable
chmod a+x /usr/lib/cgi-bin/*

# return to sandbox
cd ..

# check files were copied successfully
IND="/var/www/index.html"
FORM="/var/www/form.html"
AFPL="/usr/lib/cgi-bin/accept_form.pl"
HW="/usr/lib/cgi-bin/hello_world.pl"
TDB="/usr/lib/cgi-bin/testdb.pl"

if [ -e "$IND" ] && [ -e "$FORM" ] && [ -e "$AFPL" ] && [ -e "$HW" ] && [ -e "$TDB" ]
then
	echo "HTML and Perl files in place"
else
	echo "HTML and Perl files NOT in place"
	ERRORCHECK=$((ERRORCHECK+1))
fi

# tar it back up
tar -zcvf webpackage_preTest.tgz DeploymentWebApp

# # move to test dir and clean up
mv webpackage_preTest.tgz ../test
rm -rf DeploymentWebApp

# untar
cd ../test
tar -zxvf webpackage_preTest.tgz

# perform test/manipulation
# check static content is properly constructed
tidy /var/www/*

# test dynamic content functions as required
# ie perl script enters data into database
# configure mysql
echo "Testing if data added to mysql"
cat <<FINISH | mysql -uroot -ppassword
drop database if exists dbtest;
CREATE DATABASE dbtest;
GRANT ALL PRIVILEGES ON dbtest.* TO dbtestuser@localhost IDENTIFIED BY 'dbpassword';
use dbtest;
drop table if exists custdetails;
create table if not exists custdetails ( name VARCHAR(30) NOT NULL DEFAULT '', address VARCHAR(30) NOT NULL DEFAULT '' );
insert into custdetails (name,address) values ('Niall Ryan', 'Rathmines');
select * from custdetails;
FINISH
echo "Data added... Look at the line above"

# add more tests here

# tar package back up
tar -zcvf webpackage_preDeploy.tgz DeploymentWebApp

# check that ERRORCHECK is not 0
if [ $ERRORCHECK -eq 0 ]
then
	# backup content
	# mysqldump > db_backup
	# scp db_backup testuser@whatever_BID_server_ip_is

	# move webpackage + monitoring script to deployment server
	
	scp -i ~/keypair1.pem webpackage_preDeploy.tgz ubuntu@ec2-54-194-154-110.eu-west-1.compute.amazonaws.com:~
	#
	# ssh into AWS instance
	ssh -t -i ~/keypair1.pem ubuntu@ec2-54-194-154-110.eu-west-1.compute.amazonaws.com bash deploy.sh
	
	echo "Deployment completed successfully."
else
	echo "Errors in Build, Integration or Test Phase... exiting..."
	exit
fi
