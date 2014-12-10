echo " "
echo " -----------------------------------------------------------------------"
echo "|                                Logs                                   |"
echo " -----------------------------------------------------------------------"
echo " "

LogDirectory=$( find /var/www -name 'log' | grep -v '.proj' )
if [ ! -z "LogDirectory" ]
then
	LogDir="$LogDirectory"
else
	LogDir='/log'
fi	

# The "replace" function Handles sed insert commands
replace(){ sed -i -e "s/$(echo $1 | sed -r 's/\//\\\//g' | sed -r 's/ /\\\s\*/' | sed -r 's/\[/\\\[/' | sed -r 's/\]/\\\]/')/$( echo $2 | sed -r 's/\//\\\//g' | sed -r 's/\[/\\\[/g' | sed -r 's/\]/\\\]/g')/" $3; } 

# The "logFolder" function prints the name of the folder the logs are being written to
logFolder(){ echo $1 | sed "s/\/$2//" | grep -o '/.*' | tr -d '/';}

# The "Confi" variale is an array of the configuration files in the Nginx sites-available directory, which allows editing of each configuration file in that directory in a for loop
Confi=$( ls /etc/nginx/sites-available )

# Find the log directory for Nginx
nginxLogs=$( find "$LogDir" -name 'nginx' )

# If the Nginx log directory was found then write error logs to it
if [ "$logDir" != "/log" ] && [ ! -z "$nginxLogs" ]
then
	replace "error_log  /var/log/nginx/error.log warn;" "error_log  $nginxLogs/conf.error.log warn;" /etc/nginx/nginx.conf

	# Edit each configuration file in sites-available folder to output logs into the Nginx log directory
	for Fil in $Confi
	do
		replace "access_log  /var/log/nginx/host.access.log;" "access_log  $nginxLogs/host.access.log;" /etc/nginx/sites-available/$Fil && \
		replace "error_log  /var/log/nginx/error.log;" "error_log  $nginxLogs/error.log;" /etc/nginx/sites-available/$Fil
	done
	echo -e "  - outputting Nginx logs to host log folder /web/root/$( echo $nginxLogs | sed -e 's/\/var\/www\///g' )"
else
	echo '  - outputting Nginx logs to internal log folder /log'
fi
