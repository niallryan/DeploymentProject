#!/bin/bash

# set ADMIN and MAILSERVER vars for mail script
ADMINISTRATOR=carolineryan57@eircom.net
MAILSERVER=mail1.eircom.net

# Level 1 Functions

# check if apache is running
function isApacheRunning {
	isRunning apache2
	return $?
}

# check is apache is listening
function isApacheListening {
	isTCPlisten 80
	return $?
}

# check if mysql is listening
function isMysqlListening {
	isTCPlisten 3306
	return $?
}

# check if apache remote is up
function isApacheRemoteUp {
	isTCPremoteOpen 127.0.0.1 80
	return $?
}

# check if mysql is running
function isMysqlRunning {
	isRunning mysqld
	return $?
}

# check if mysql remote is up
function isMysqlRemoteUp {
	isTCPremoteOpen 127.0.0.1 3306
	return $?
}


# Level 0 Functions

function isRunning {
	PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
	if [ $PROCESS_NUM -gt 0 ]; then
		echo $PROCESS_NUM
		return 1
	else
		return 0
	fi
}

function isTCPlisten {
	TCPCOUNT=$(netstat -tupln | grep tcp | grep "$1" | wc -l)
	if [ $TCPCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

function isUDPlisten {
	UDPCOUNT=$(netstat -tupln | grep udp | grep "$1" | wc -l)
	if [ UDPCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

function isTCPremoteOpen {
	timeout 1 bash -c "echo > /dev/tcp/$1/$2" && return 1 || return 0
}

function isIPalive {
	PINGCOUNT=$(ping -c 1 "$1" | grep "1 received" | wc -l)
	if [ $PINGCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

function getCPU {
	app_name=$1
	cpu_limit="5000"
	app_pid=`ps aux | grep $app_name | grep -v grep | awk {'print $2'}`
	app_cpu=`ps aux | grep $app_name | grep -v grep | awk {'print $3*100'}`
	if [[ $app_cpu -gt $cpu_limit ]]; then
		return 0
	else
		return 1
	fi
}

# Functional Body of Script

ERRORCOUNT=0

isApacheRunning
if [ "$?" -eq 1 ]; then
	echo Apache Process is Running
else
	echo Apache Process is NOT running
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

isApacheListening
if [ "$?" -eq 1 ]; then
	echo Apache is Listening
else
	echo Apache is NOT listening
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

isApacheRemoteUp
if [ "$?" -eq 1 ]; then
	echo Remote Apache TCP port is UP
else
	echo Remote Apache TCP port is DOWN
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

isMysqlRunning
if [ "$?" -eq 1 ]; then
	echo mySQL process is Running
else
	echo mySQL process is NOT Running
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

isMysqlListening
if [ "$?" -eq 1 ]; then
	echo mySQL is listening
else
	echo mySQL is NOT listening
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

isMysqlRemoteUp
if [ "$?" -eq 1 ]; then
	echo Remote mySQL TCP port is UP
else
	echo Remote mySQL TCP port is DOWN
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

if [ $ERRORCOUNT -eq 0 ]
then
	echo "ERROR! ERROR! There is a problem with SOMETHING!" | perl sendmail.pl $ADMINISTRATOR $MAILSERVER
fi
