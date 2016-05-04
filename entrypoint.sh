#!/bin/sh
set -e

shutdown_http(){
 httpd -k stop  || true
 exit 0
}

make_override(){
 mkdir -p $SUGAR_HOME
 ovr_conf=/etc/apache2/conf.d/sugar.conf
 touch $ovr_conf
 echo "<Directory ${SUGAR_HOME}/>
          Options Indexes FollowSymLinks
          AllowOverride All
          Require all granted
       </Directory>
" > $ovr_conf
}

patch_phpini(){ 
  php_ini=/etc/php/php.ini
  sed -i 's/memory_limit = .*/memory_limit = '${PHP_MEM_LIMIT}'/' $php_ini
  sed -i 's/upload_max_filesize = .*/upload_max_filesize = '${PHP_UPLOAD_LIMIT}'/' $php_ini
}



make_install_configs(){
#$1 - root installation folder
sugar_root=$1
sugar_si=$SUGAR_HOME/$sugar_root/config_si.php
touch $sugar_si
chown $APACHE_USER:$APACHE_GROUP $sugar_si

url="http://localhost/$SUGAR_BASE/$sugar_root"
dbuser=$DB_USER
dbpwd=$DB_PASS

case "$SUGAR_DB_TYPE" in
	oci8)
		wait_for_oracle
		db_name=$TNS_NAME
		db_host=$ORACLE_HOST
		crdb=0
		;;
	*)
		wait_for_mysql
		db_name="sugar"
		db_host=$MYSQL_HOST
		crdb=1
		;;
esac

echo "
<?php
 
\$sugar_config_si = array (
  'setup_site_admin_user_name'=>'admin',
  'setup_site_admin_password' => 'admin',
  'setup_fts_type' => 'Elastic',
  'setup_fts_host' => '$ELASTIC_HOST',
  'setup_fts_port' => '$ELASTIC_PORT',
 
  'setup_db_host_name' => '$db_host',
  'setup_db_database_name' => '$db_name',
  'setup_db_drop_tables' => 1,
  'setup_db_create_database' => $crdb,
  'setup_db_admin_user_name' => '$dbuser',
  'setup_db_admin_password' => '$dbpwd',
  'setup_db_type' => '$SUGAR_DB_TYPE',
 
  'setup_license_key' => '$SUGAR_LICENSE',
  'setup_system_name' => 'SugarCRM',
  'setup_site_url' => '$url',
  'demoData' => 'no',
);
" > $sugar_si

echo "Configuration summary:"
echo "=============================="
echo "Database type: $SUGAR_DB_TYPE"
echo "Database host: $db_host"
echo "Database name: $db_name"
echo "Database user(admin): $dbuser"
echo "Setup URL: $url"
echo "Elastic host: $ELASTIC_HOST"
echo "Elastic port: $ELASTIC_PORT"

}

wait_for_mysql(){
 echo -n "Checking for MYSQL server: $MYSQL_HOST"
 while ! mysqladmin ping -h "$MYSQL_HOST" --silent >/dev/null 2>&1; do
	 echo -n "."
	 sleep 1
 done
 echo
 echo "MYSQL server is seems ok: $MYSQL_HOST"
}


sugar_install(){
 #$1 - Sugar installation ZIP file
 sugar_zip=$1

 #root folder name inside a zip archive without trailing slashes
 sugar_root=`unzip -qql $sugar_zip | head -n1 | tr -s ' '| cut -d' ' -f5- | sed 's/\/$//' `
 echo -n "About to unzip installation files... "
 unzip -qq -o $sugar_zip -d $SUGAR_HOME
 echo "done"
 echo "Making silent installl configuration for: $SUGAR_DB_TYPE"
 make_install_configs $sugar_root
 install_url="http://localhost/$SUGAR_BASE/$sugar_root/install.php?goto=SilentInstall&cli=true"
 chown -R $APACHE_USER:$APACHE_GROUP $SUGAR_HOME/$sugar_root
 chmod 777 $SUGAR_HOME/$sugar_root
 echo "Running silent installation of:  $sugar_root"
 result_html=$(curl -XGET $install_url 2>/dev/null)
 res_ok="<bottle>Success!</bottle>" 
 if test "${result_html#*$res_ok}" != "$result_html"; then 
	 echo "$sugar_root has been installed sucessfully, please check /tmp/${sugar_root}_intsall_log.html for details"
 else
	 echo "$sugar_root Installation FAILED, please check /tmp/${sugar_root}_intsall_log.html for details"
 fi
 echo $result_html > /tmp/${sugar_root}_intsall_log.html
 mv ${sugar_zip} ${sugar_zip}.processed
}

run_init_scripts(){
 exec="Processing data in: /sugar.d/"
 for f in /sugar.d/*; do
	 case $f in
		 *.zip)
			 echo "Potential sugar installation found: $f"
			 echo "Will try to intsall bundle automatically"
			 sugar_install $f
			 ;;
		 *.sh)
			 echo "Executing shell script $f"
			 source $f || true
			 ;;
		*)
			echo "Ignoring $f"
			;;
	esac
 done
}



case "$1" in
    '')
       patch_phpini && echo "PHP settings applied sucessfully"
       make_override && echo "Configuring apache permissions"
       echo "<?php echo phpinfo() ?>" > $SUGAR_HOME/info.php
       chown -R $APACHE_USER:$APACHE_GROUP $WEB_ROOT
       httpd -k start
       echo "HTTP server is ready"
       run_init_scripts
       echo "All done, image is ready to use"
       while [ "$END" == '' ]; do
         sleep 1
         trap "shutdown_http" INT TERM
       done
       ;;
    *)
      echo "Running wild. Run entrypoint.sh if required"
      $1
     ;;
esac
