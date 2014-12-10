#!/bin/bash -l

#get configuration variables
Name=$(env | egrep 'ADDR' | egrep -o '^[^_]+' | grep -v -E '(HOSTNAME=|TERM|PWD|SHLVL|HOME|PATH)') 

#if there are no connection variables to connect to, report that nginx has not connected to outside containers
if [[ -z "$Name" ]]
then
	echo " -----------------------------------------------------------------------"
	echo " "	 
	echo "  - Nginx server is not connected to any outside containers"
else
	conf.sh
fi

permissions.sh
logs.sh	
webRoot.sh

echo " "

# nginx
exec nginx
