#!/usr/bin/env bash
##########
#Keystone
#http://docs.openstack.org/mitaka/install-guide-ubuntu/keystone-install.html
##########
KEYSTONE_DBPASS="$DEFAULT_PASS"

echo "CREATE DATABASE keystone;"    "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';"    "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';"    | mysql --user=root --password=$DEFAULT_PASS

#Disable the keystone service from starting automatically
sudo sh -c "echo 'manual' > /etc/init/keystone.override"

sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install keystone apache2 libapache2-mod-wsgi
export ADMIN_TOKEN=$(openssl rand -hex 10)
sudo sed --in-place     -e "s/^#admin_token.=.*/admin_token=$ADMIN_TOKEN/"     -e "s/^connection.=.*/connection = mysql+pymysql:\/\/keystone:${KEYSTONE_DBPASS}@controller\/keystone/"     -e 's/^provider.=.*/provider = fernet/'     /etc/keystone/keystone.conf
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

sudo bash -c "echo -e '
ServerName controller' >> /etc/apache2/apache2.conf"
sudo sh -c 'cat <<EOT > /etc/apache2/sites-available/wsgi-keystone.conf
Listen 5000
Listen 35357

<VirtualHost *:5000>
  WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
  WSGIProcessGroup keystone-public
  WSGIScriptAlias / /usr/bin/keystone-wsgi-public
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
  ErrorLogFormat "%{cu}t %M"
  ErrorLog /var/log/apache2/keystone.log
  CustomLog /var/log/apache2/keystone_access.log combined

  <Directory /usr/bin>
    Require all granted
  </Directory>
</VirtualHost>

<VirtualHost *:35357>
  WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
  WSGIProcessGroup keystone-admin
  WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
  ErrorLogFormat "%{cu}t %M"
  ErrorLog /var/log/apache2/keystone.log
  CustomLog /var/log/apache2/keystone_access.log combined

  <Directory /usr/bin>
    Require all granted
  </Directory>
</VirtualHost>
EOT'

sudo ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
sudo service apache2 restart
sudo rm -f /var/lib/keystone/keystone.db

#http://docs.openstack.org/mitaka/install-guide-ubuntu/keystone-services.html
export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
openstack service create --name keystone --description "OpenStack Identity" identity
openstack endpoint create --region RegionOne identity public http://controller:5000/v3
openstack endpoint create --region RegionOne identity internal http://controller:5000/v3
openstack endpoint create --region RegionOne identity admin http://controller:35357/v3

#http://docs.openstack.org/mitaka/install-guide-ubuntu/keystone-users.html
openstack domain create --description "Default Domain" default
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password $DEFAULT_PASS admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password demo demo
openstack role create user
openstack role add --project demo --user demo user
sudo sed --in-place -e 's/\(^pipeline.=.*\)admin_token_auth/\1/' /etc/keystone/keystone-paste.ini
unset OS_TOKEN OS_URL
cat <<EOT > ~\admin-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$DEFAULT_PASS
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOT
cat <<EOT > ~\demo-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=demo
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOT
