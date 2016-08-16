##########
#Glance
#http://docs.openstack.org/mitaka/install-guide-ubuntu/glance-install.html
##########
GLANCE_DBPASS="$DEFAULT_PASS"
GLANCE_PASS="$DEFAULT_PASS"

. admin-openrc
echo 'CREATE DATABASE glance;'    "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';"     "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';"     | mysql --user=root --password=$DEFAULT_PASS

openstack user create --domain default --password $GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install glance

sudo cp -npv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.original
sudo sed --in-place \
  -e "s/^.connection.=.*/connection = mysql+pymysql:\/\/glance:${GLANCE_PASS}@controller\/glance/" \
  -e 's/^.auth_uri.=.*/auth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/' \
  -e 's/^.memcached_servers.=.*/memcached_servers = controller:11211/' \
  -e "s/^.auth_type.=.*/auth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = glance\npassword = $GLANCE_PASS/" \
  -e 's/^.flavor.=.*/flavor = keystone/' \
  -e 's/^.stores.=.*/stores = file,http/' \
  -e 's/^.default_store.=.*/default_store = file/' \
  -e 's/^.filesystem_store_datadir.=.*/filesystem_store_datadir = \/var\/lib\/glance\/images\//' \
  /etc/glance/glance-api.conf
  #-e 's/\(^sqlite_db.=.*\)/#\1/'
sudo cp -npv /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.original
sudo sed --in-place \
  -e "s/^connection.=.*/connection = mysql+pymysql:\/\/glance:${GLANCE_PASS}@controller\/glance/" \
  -e 's/^.*auth_uri.=.*/auth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/' \
  -e 's/^.*memcached_servers.=.*/memcached_servers = controller:11211/' \
  -e "s/^.*auth_type.=.*/auth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = glance\npassword = $GLANCE_PASS/" \
  -e 's/^.*flavor.=.*/flavor = keystone/'
  /etc/glance/glance-registry.conf
  #-e 's/\(^sqlite_db.=.*\)/#\1/'
sudo su -s /bin/sh -c "glance-manage db_sync" glance
sudo service glance-registry restart
sudo service glance-api restart
