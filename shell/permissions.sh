#!/bin/bash

echo " "
echo " -----------------------------------------------------------------------"
echo "|                             Permissions                               |"
echo " -----------------------------------------------------------------------"
echo " "

# handles sed insert commands
replace(){ sed -i -e "s/$(echo $1 | sed -r 's/\//\\\//g' | sed -r 's/ /\\\s\*/' | sed -r 's/\[/\\\[/' | sed -r 's/\]/\\\]/')/$( echo $2 | sed -r 's/\//\\\//g' | sed -r 's/\[/\\\[/g' | sed -r 's/\]/\\\]/g')/" $3; } 

# The "rootFolder" function causes find to only return search results before a specified directory name, i.e. do not return any similarly named directories or files inside the named directory
rootFolder(){ echo $( find $2 -name "$1" -not -path "*$1/*"); }

# "webRootExists" finds the path to the web root directory defined in the "WEB_ROOT" environment variable
webRootExists=$( rootFolder $WEB_ROOT /var/www/ )

# fid path to web root
if [[ ! -z "$webRootExists" ]]
then
	webRoot="$webRootExists"
else
	webRoot="/var/www"
fi

# set user and group id to default www-data if they are not defined in environment variables
if [ -z "$HUSER" ] || [ "$HUSER" == "root" ]
then
        user="www-data"
else
        user="$HUSER"
fi

if [ -z "$GROUP" ] || [ "$GROUP" == "root" ]
then
        group="www-data"
else
        group="$GROUP"
fi

# set permissions for web root
adduser $user> /dev/null 2>&1
chmod -R 755 "$webRoot" > /dev/null 2>&1 || permissions="  - Permissions could not be changed on host"
chown -R $group:$user $webRoot > /dev/null 2>&1 || permissions="  - Permissions could not be changed host"
if [ "$permission" == "  - Permissions could not be changed on host" ]
then
	echo $permissions
fi
replace "user  nginx;" "user  $user;" /etc/nginx/nginx.conf && \
echo -e "  - User set to \"$user\", Group set to \"$group\""
