#!/bin/bash

cd /tmp

# create sandbox
SANDBOX=sandbox_$RANDOM
mkdir $SANDBOX
echo Using sandbox $SANDBOX
cd $SANDBOX

# set errorcheck variable to 0
ERRORCHECK=0

# get webpackage for testing
git clone https://github.com/niallryan/DeploymentWebApp.git

# create process folders
mkdir build
mkdir integrate
mkdir test

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


# tar it back up
tar -zcvf webpackage_preIntegrate.tgz DeploymentWebApp

# set ERRORCHECK if any errors

# move webpackage to Integrate dir and clean up
mv webpackage_preIntegrate.tgz ../integrate
rm -rf DeploymentWebApp

# untar
cd ../integrate
tar -zxvf webpackage_preIntegrate.tgz

# perform integrate/manipulation functions

# tar it back up
tar -zcvf webpackage_preTest.tgz DeploymentWebApp

# set ERRORCHECK if any errors

# move to test dir and clean up
mv webpackage_preTest.tgz ../test
rm -rf DeploymentWebApp

# untar
cd ../test
tar -zxvf webpackage_preTest.tgz

# perform test/manipulation functions

# tar it back up
tar -zcvf webpackage_preDeploy.tgz DeploymentWebApp

# set ERRORCHECK if any errors

# check that ERRORCHECK is not 0
if [ $ERRORCHECK -eq 0 ]
then
	# move webpackage + deployment script to AWS server

	# untar file

	# perform deployment

	echo Doing Deployment
fi
