Nginx
=====

Nginx built in a CentOS Docker container

This Container was built to automatically edit Nginx's configuration files to connect with linked outside containers. The container detects the hostname of a container like Php-fpm for example and then edits the necessary configurations to connect to that outside container and serve content from it. 

The Nginx container will also detect if it is linked to Laravel and if found will move its web root to the linked Laravel project's public directory. If Nginx has found that it is connected to Laravel but Laravel is in the process of installing, Nginx will wait until either the laravel public directory has been created or it has timed out to set its web root to the appropriate location. 

If Laravel is not present or has timed out, Nginx will search its /var/www directory for a directory name defined in the 'WEB_ROOT' environment variable, if the directory specified is found, nginx will set its web root directory to that directory and serve it's contents.

Environment Variables:
=
Though the Nginx container is intended to link and operate automatically, the following environment variables may be set if desired to change the containers functionality:

'HOSTNAME'
-
Sets the host name for the nginx container 

'PERMISSIONS'
-
sets the level of permissions granted to the user specified in the 'HUSER' variable

example: 'PERMISSIONS=755'

'HUSER'
-
Sets the user name used by nginx

'GROUP'
-
Sets the name of the user group used by nginx

'NGINX_IP'
-
sets a custom ip addresses for nginx to lisen on

'WEB_ROOT'
-
 name of web root directory ( sets the web root path in nginx )
 
'TIMEOUT'
-
 sets the php timeout time in seconds for Nginx 
 
 example: 'TIMEOUT=60s'



