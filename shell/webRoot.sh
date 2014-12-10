#!/bin/bash

echo " "
echo " -----------------------------------------------------------------------"
echo "|                                Paths                                  |"
echo " -----------------------------------------------------------------------"
echo " "

# The "escape" function escapes charecters for sed commands
escape(){ echo $1  | sed -r 's/\//\\\//g'; }

# the "replace" function handles sed insert commands
replace(){ sed -i -e "s/$(echo $1 | sed -r 's/\//\\\//g' | sed -r 's/ /\\\s\*/' | sed -r 's/\[/\\\[/' | sed -r 's/\]/\\\]/')/$( echo $2 | sed -r 's/\//\\\//g' | sed -r 's/\[/\\\[/g' | sed -r 's/\]/\\\]/g')/" $3; } 

# The "rootFolder" function causes find to only return search results before a specified directory name, i.e. do not return any similarly named directories or files inside the named directory
rootFolder(){ echo $( find $2 -name "$1" -not -path "*$1/*"); }

# "webRootExists" and "webRootDir" hold paths to the web root directory defined in the "WEB_ROOT" environment variable and its parent directory
webRootExists=$( rootFolder $WEB_ROOT /var/www/ )
webRootDir=$( echo $webRootExists | sed "s/\/$(escape $WEB_ROOT)//" )

# if the web root path is found then create a symlink for an ssl configuration
if [[ ! -z "$webRootExists" ]]
then
	webRoot="$webRootExists" && \
	ln -s $webRootExists $webRootDir/ssl> /dev/null 2>&1

# if the web root is not found in the volume, make the volume the webroot folder and create a symlink th
else
	webRoot="/var/www"
	ln -s $webRootExists $webRootDir/ssl> /dev/null 2>&1
fi

echo "  - symlink created for ssl access to web root directory"

# find the path to the Php web root directory
phpWebRoot=$( rootFolder php $webRoot )
laravelExists=$( env | grep '_ENV_INSTALL_LARAVEL' | grep -o '=.*' | tr -d '=' )
# get a list of the Nginx server configuration files 
Confi=$( ls /etc/nginx/sites-available )

# add the web root paths to each configuration file found in the nginx sites-available directory 
for Files in $Confi
do
	# if Laravel has been told to install then wait for it to install before setting its path in Nginx
	if [ ! -z "$laravelExists" ] 
	then
		x=0
		until [[ ! -z $( find /var/www/ -name "*.proj" ) ]]
		do 
			sleep 1 && x=$(($x+1))
			if [[ "$x" -gt "300" ]]
			then		
				break
			fi
		done
	fi
	
	# get a list of Laravel projects
	laravelWebRoot=$( find /var/www/ -name "*.proj" )
	
	# set up configurations for Laravel if it is installed
	if [ ! -z "$laravelWebRoot" ]
	then		
		echo '  - Laravel Project found, setting web root to the Laravel public folder'
		
		# for each Laravel project found
		for projectPath in $laravelWebRoot
		do
			# get the name of the project folder
			projectName=$( basename $projectPath )
			
			# get the name of the project ( folder name without extension )
			webPath=$( echo $projectName | sed 's/.proj//g' )
			
			# check to see if nginx already has configurations for specified project
			isPathSet=$( grep "$webPath" /etc/nginx/sites-available/$Files )
			
			# if the configurations for the specified Laravel project havent already been set then set them
			if [ -z "$isPathSet" ]
			then
				sed -i -e "s/.*    location \/proxy\/ {.*/	location \/$webPath\/ {\n		root    $( escape $projectPath )\/public;\n		try_files \$uri \$uri\/ \/index.php?\$query_string;\n	}\n\n&/" /etc/nginx/sites-available/$Files # && \
				# echo "  - Path to Laravel url set to /$webPath"
			fi
		done
		replace "root        /var/www;" "root        $laravelWebRoot/public;" /etc/nginx/sites-available/$Files && \
		echo "  - Web root directory set to /web/root/$( echo $laravelWebRoot/public | sed -e 's/\/var\/www\///g' ) in $Files" || \
		echo "  - web root directory not found"	
	else
		# set web root path for nginx
		replace "root        /var/www;" "root        $webRoot;" /etc/nginx/sites-available/$Files && \
		echo "  - Web root directory set to /web/root/$( echo $webroot | sed -e 's/\/var\/www\///g' ) in $Files" || \
		rm -rf "$webRoot/$WEB_ROOT"
	fi
done