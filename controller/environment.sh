#!/usr/bin/env bash
##########
#Enviroment
#http://docs.openstack.org/mitaka/install-guide-ubuntu/environment.html
##########

#Database
#http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-sql-database.html
sudo debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password password $DEFAULT_PASS"
sudo debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password_again password $DEFAULT_PASS"
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install mariadb-server python-pymysql
sudo sh -c "cat <<EOT >> /etc/mysql/conf.d/openstack.cnf
[mysqld]
bind-address = $IP_CONTROLLER
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOT"
#mysql_secure_installation
mysql --user=root --password=$DEFAULT_PASS <<EOT
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
EOT
sudo service mysql restart

#Message queue
#http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-messaging.html
RABBIT_PASS="$DEFAULT_PASS"
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install rabbitmq-server
sudo rabbitmqctl add_user openstack $RABBIT_PASS
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#Memcached
#http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-memcached.html
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install memcached python-memcache
sudo sed --in-place "s/-l 127\.0\.0\.1/-l $IP_CONTROLLER/" /etc/memcached.conf
sudo service memcached restart
