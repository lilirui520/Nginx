#  --------------
# | source image |
#  --------------

FROM centos:centos6

# My info
MAINTAINER Ruddickmg@gmail.com

#  ---------------
# | install nginx |
#  ---------------

RUN touch /etc/yum.repos.d/nginx.repo;
RUN echo -e "[nginx]\nname=nginx repo\nbaseurl=http://nginx.org/packages/centos/6/\$basearch/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/nginx.repo;
RUN yum install -y nginx
RUN mkdir /etc/nginx/sites-available

#  --------------------------------------------
# | edit and add configuration files for nginx |
#  --------------------------------------------

RUN sed -i -e "s/#gzip\s*\s*on;/gzip  on;/" /etc/nginx/nginx.conf
RUN sed -i -e "s/include\s*\/etc\/nginx\/conf.d\/\*.conf;/\include \/etc\/nginx\/conf.d\/\*.conf;\n    include \/etc\/nginx\/sites-enabled\/\*;/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/conf.d/*
ADD conf/php.conf /etc/nginx/conf.d/php.conf
ADD conf/proxy.conf /etc/nginx/conf.d/proxy.conf
ADD conf/serve.conf /etc/nginx/conf.d/serve.conf
ADD conf/charset.conf /etc/nginx/conf.d/charset.conf
ADD conf/expires.conf /etc/nginx/conf.d/expires.conf
ADD conf/gzip.conf /etc/nginx/conf.d/gzip.conf
ADD conf/ssl.conf /etc/nginx/conf.d/ssl.conf
ADD conf/btp.conf /etc/nginx/sites-available/btp.conf
#ADD conf/btpssl.conf /etc/nginx/sites-available/btpssl.conf
RUN ln -s /etc/nginx/sites-available /etc/nginx/sites-enabled

#  --------------------------
# | make external log volume |
#  --------------------------

RUN mkdir /log

#  ------------------------
# | allow view of logs etc |
#  ------------------------

VOLUME ["/log/nginx", "/etc/nginx"]

#  ----------------------
# | open ports for nginx |
#  ----------------------

EXPOSE 80 443

#  -------------------------
# | set container host name |
#  -------------------------

ENV HOSTNAME nginx

#  ---------------------------------------------------
# | set level of permissions granted for created user |
#  ---------------------------------------------------

ENV PERMISSIONS 755

#  --------------------------------------------------
# | set user and group created for nginx permissions |
#  --------------------------------------------------

ENV HUSER www-data
ENV GROUP www-data

#  ------------------------------------------------
# | set ip addresses to lisen on for nginx and php |
#  ------------------------------------------------

# ENV NGINX_IP localhost

#  ----------------------------------------------------------------
# | name of web root directory ( sets the web root path in nginx ) |
#  ----------------------------------------------------------------

ENV WEB_ROOT scripts

#  -------------------------------------------
# | set php timeout time in seconds for Nginx |
#  -------------------------------------------	

ENV TIMEOUT 900s

#  ---------------------
# | add startup scripts |
#  ---------------------

ADD shell/start.sh /bin/start.sh
RUN chmod +x /bin/start.sh
ADD shell/permissions.sh /bin/permissions.sh
RUN chmod +x /bin/permissions.sh
ADD shell/webRoot.sh /bin/webRoot.sh
RUN chmod +x /bin/webRoot.sh
ADD shell/logs.sh /bin/logs.sh
RUN chmod +x /bin/logs.sh
ADD shell/conf.sh /bin/conf.sh
RUN chmod +x /bin/conf.sh

#  -----------------------------------
# | run startup script as login shell |
#  -----------------------------------

ENTRYPOINT ["/bin/bash", "-c", "-l"]
CMD [". start.sh"]
