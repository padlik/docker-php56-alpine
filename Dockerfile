FROM alpine

RUN apk --update add php-apache2 curl php-cli php-json php-phar php-openssl php-curl php-dom php-mcrypt php-zip php-xml php-bcmath php-mysql php-ctype php-zlib apache2-proxy mysql-client && \
    rm -f /var/cache/apk/* && \
    mkdir -p /run/apache2 && \
    sed -i 's,#LoadModule cgi_module lib/apache2/mod_cgi.so,LoadModule cgi_module modules/mod_cgi.so,g' /etc/apache2/httpd.conf && \
    sed -i 's,#LoadModule mime_magic_module,LoadModule mime_magic_module,g' /etc/apache2/httpd.conf && \
    sed -i 's,#LoadModule rewrite_module,LoadModule rewrite_module,g' /etc/apache2/httpd.conf && \
    sed -i 's,#LoadModule deflate_module,LoadModule deflate_module,g' /etc/apache2/httpd.conf && \
    sed -i 's,#LoadModule slotmem_shm_module,LoadModule slotmem_shm_module,g' /etc/apache2/httpd.conf && \
    echo "Installation Success" 


ENV SUGAR_BASE=sugar 
ENV WEB_ROOT=/var/www/localhost/htdocs 
ENV SUGAR_HOME=$WEB_ROOT/$SUGAR_BASE 
ENV SUGAR_LICENSE='<>' 
ENV SUGAR_DB_TYPE=mysql 

ENV MYSQL_HOST=mysql 
ENV MYSQL_PORT=3306 
ENV DB_USER=sugar
ENV DB_PASS=sugar

ENV ELASTIC_HOST=elastic
ENV ELASTIC_PORT=9200

ENV APACHE_USER=apache
ENV APACHE_GROUP=apache

ENV PHP_MEM_LIMIT=1024M
ENV PHP_UPLOAD_LIMIT=20M

ENV SUGAR_AUTO="/sugar.d" 

EXPOSE 80

COPY entrypoint.sh /entrypoint.sh

VOLUME ["$SUGAR_HOME"]
VOLUME ["/sugar.d"]
ENTRYPOINT ["/entrypoint.sh"]
