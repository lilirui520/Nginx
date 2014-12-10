#!/bin/bash 

echo " "
echo " -----------------------------------------------------------------------"
echo "|                         Nginx Configurations                          |"
echo " -----------------------------------------------------------------------"
echo " "

# The "escape" function escapes charecters for sed commands 
escape(){ echo $1  | sed -r 's/\//\\\//g'; }

# "Name" is the alias for the docker link connection
Name=$( env | grep 'ADDR' | egrep -o '^[^_]+' | uniq ) 

# This command makes string comparisons case insensitive
shopt -s nocasematch

# For each linked container do the following
for Alias in $Name;
do 
    # "Hname", "Port" and "Addr" are the hostname port and address for each linked container
	Hname=$(env | grep $Alias'_ENV_HOSTNAME=' | grep -o '=.*' | tr -d '", =') 
	Port=$(env | egrep 'PORT='| egrep $Alias | egrep -v ':' | egrep -o '=.*' | tr -d '=')
	Addr=$(env | egrep $Alias'_PORT_'$Port'_TCP_ADDR=' | grep -o '=.*' | tr -d '=')

	# The "hostnames" function adds hostnames to nginx configuration file
	hostnames(){
		for File in $1
		do
			Server=$(grep "server_name" /etc/nginx/sites-available/$File | tr -d "\;")
			sed -i -e "s/$Server/$Server $2/" /etc/nginx/sites-available/$File && \
			echo "  - Host $2 added to $1"
		done
	} 

	# The "serverConfig" function configures Nginx .conf files with server information
	serverConfig(){	
	
		# If the ip address in the file is the same as default and is not set to local host then change the address to the container port
		if [ "$(grep 'server' /etc/nginx/conf.d/$5)" == "	server $1;"  ] && [ -z "$6" ]; then
   			sed -i -e "s/server\s*$2;/server $3:$4;/" /etc/nginx/conf.d/$5   
		elif [ "$6" != "localhost" ]  && [ ! -z "$6" ];  then
			sed -i -e "s/.*$( grep 'server' /etc/nginx/conf.d/$5 | sed -r 's/\//\\\//g').*/	server $6:$4;\n&/" /etc/nginx/conf.d/$5
		else
			sed -i -e "s/.*$( grep 'server' /etc/nginx/conf.d/$5 | sed -r 's/\//\\\//g').*/	server $3:$4;\n&/" /etc/nginx/conf.d/$5
		fi 
	}

	# The "hostExists" function reports whether there is a host name to identify the connection with
	hostExists(){
		if [[ ! -z "$1" ]]; then
			echo -e "Nginx_is_listening_to_$(echo $1)_at_$3:$4" 
		else
			echo "Nginx_is_listening_to_unknown_host_connection:_\"$2\"_a_$3:$4" 
		fi
	}
	
	# The "localhost" function prints localhost instead of the numeric address if the host/ip address is set to that value
	localhost(){ 
		if [ "$2" == "localhost" ] || [ "$2" == "127.0.0.1" ]; then
			echo "  - $1" | sed "s/_/ /g" | sed "s/$3:$4/localhost/g"
		else
			echo "  - $1" | sed "s/_/ /g"
		fi
	}

	# Report connection information to terminal	
	localhost $(hostExists $Hname $Alias $Addr $Port) $NGINX_IP $Addr $Port 

	# Get an array of the configuration files in the sites-available directory so that each of them can be edited
	Confi=$( ls /etc/nginx/sites-available )
		
	# If the host name is php then edit Nginx's php-fpm configuration
	if [ "$Hname" == "php-fpm" ] || [ "$Hname" == "php" ] || [ "$Hname" == "php[0-9]" ]
	then
		hostnames $Confi $Hname	 	   
       	serverConfig  "127.0.0.1:9000" "127.0.0.1:9000" $Addr $Port php.conf $NGINX_IP 
		
	# If host name is mysql or mariadb add it to nginx accepted hosts
	elif [ "$Hname" == "mariadb" ] || [ "$Hname" == "mysql" ]		
	then 
		hostnames $Confi $Hname	

	# If host name is not mariadb or php edit the proxy configuration to serve connections
	else				
		hostnames $Confi $Hname
		serverConfig "http://127.0.0.1:8080" $(escape http://127.0.0.1:8080) $Addr $Port serve.conf $NGINX_IP    
	fi
done

# set the timeout duration in seconds for php-fpm
if [ ! -z $TIMEOUT ]; then
for File in $Confi; do
	sed -i -e "s/fastcgi_read_timeout\s*60s;/fastcgi_read_timeout $TIMEOUT;/" /etc/nginx/sites-available/$File
done
fi

# Ends the previous case sensitivity command
shopt -u nocasematch
