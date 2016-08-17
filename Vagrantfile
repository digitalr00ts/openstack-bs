# -*- mode: ruby -*-
# vi: set ft=ruby :

$base = <<SCRIPT
  DEFAULT_PASS='vagrant'
  IP_CONTROLLER='10.0.0.11'
  IP_COMPUTE1='10.0.0.31'

  [ $(hostname) == 'controller' ] && IP="$IP_CONTROLLER"
  [ $(hostname) == 'compute1' ] && IP="$IP_COMPUTE1"

  export DEBIAN_FRONTEND=noninteractive
  echo 'apt-get update' ; sudo apt-get update -qqy
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install vim
  sudo apt-get --force-yes --assume-yes purge resolvconf

  ##########
  #Environment
  ##########

  #Network
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-networking-controller.html
  #sed --in-place 's/127\\.0\\.1\\../127\\.0\\.0\\.1/' /etc/hosts
  #sed --in-place '/controller/d' /etc/hosts
  sudo sed --in-place '/127\\.0\\.1\\./d' /etc/hosts
  #sudo sed -e '/primary network interface/d' -e '/auto eth0/d' -e '/iface eth0.*/d' /etc/interfaces

#  sudo sh -c "cat <<EOT >> /etc/network/interfaces
# Static IP for Managment interface
#auto eth0:0
#iface eth0:0 inet static
#	address $IP
#	netmask 255.255.255.0
#EOT"
  sudo sh -c 'cat <<EOT >> /etc/network/interfaces
auto eth1
iface eth1 inet manual
	up ip link set dev \\\$IFACE up
	down ip link set dev \\\$IFACE down
EOT'
  #ip address flush dev eth0
  #ip address add $IP/24 dev eth0
  sudo sh -c "cat <<EOT >> /etc/hosts

# controller
$IP_CONTROLLER		controller
# compute1
$IP_COMPUTE1		compute1
# block1
#10.0.0.41		block1
# object1
#10.0.0.51		object1
# object2
#10.0.0.52		object2
EOT"

  #Packages
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-packages.html
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install software-properties-common
  sudo add-apt-repository --yes cloud-archive:mitaka
  echo 'apt-get update' ; sudo apt-get -qqy update && \
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes dist-upgrade
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install python-openstackclient
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install chrony python-pymysql vim

  #TO DO
  #NTP
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-ntp.html
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install chrony
  echo "TEST = $TEST"
  env
SCRIPT

$controller = <<SCRIPT
  DEFAULT_PASS='vagrant'
  IP_CONTROLLER='10.0.0.11'
  IP_COMPUTE1='10.0.0.31'

  [ $(hostname) == 'controller' ] && IP="$IP_CONTROLLER"
  [ $(hostname) == 'compute1' ] && IP="$IP_COMPUTE1"

  export DEBIAN_FRONTEND=noninteractive

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
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
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
  sudo sed --in-place "s/-l 127\\.0\\.0\\.1/-l $IP_CONTROLLER/" /etc/memcached.conf
  sudo service memcached restart

  ##########
  #Keystone
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/keystone-install.html
  ##########
  KEYSTONE_DBPASS="$DEFAULT_PASS"

  echo "CREATE DATABASE keystone;"\
    "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';"\
    "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';"\
    | mysql --user=root --password=$DEFAULT_PASS

  #Disable the keystone service from starting automatically
  sudo sh -c "echo 'manual' > /etc/init/keystone.override"

  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install keystone apache2 libapache2-mod-wsgi
  export ADMIN_TOKEN=$(openssl rand -hex 10)
  sudo sed --in-place \
    -e "s/^#admin_token.=.*/admin_token=$ADMIN_TOKEN/" \
    -e "s/^connection.=.*/connection = mysql+pymysql:\\/\\/keystone:${KEYSTONE_DBPASS}@controller\\/keystone/" \
    -e 's/^provider.=.*/provider = fernet/' \
    /etc/keystone/keystone.conf
  sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
  sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

  sudo bash -c "echo -e '\nServerName controller' >> /etc/apache2/apache2.conf"
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
  sudo sed --in-place -e 's/\\(^pipeline.=.*\\)admin_token_auth/\\1/' /etc/keystone/keystone-paste.ini
  unset OS_TOKEN OS_URL
  cat <<EOT > admin-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$DEFAULT_PASS
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOT
  cat <<EOT > demo-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=demo
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOT

  ##########
  #Glance
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/glance-install.html
  ##########
  GLANCE_DBPASS="$DEFAULT_PASS"
  GLANCE_PASS="$DEFAULT_PASS"

  . admin-openrc
  echo 'CREATE DATABASE glance;'\
    "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';" \
    "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';" \
    | mysql --user=root --password=$DEFAULT_PASS

  openstack user create --domain default --password $GLANCE_PASS glance
  openstack role add --project service --user glance admin
  openstack service create --name glance --description "OpenStack Image" image
  openstack endpoint create --region RegionOne image public http://controller:9292
  openstack endpoint create --region RegionOne image internal http://controller:9292
  openstack endpoint create --region RegionOne image admin http://controller:9292

  sudo cp -npv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.original
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install glance
  sudo sed --in-place \
    -e "s/^.connection.=.*/connection = mysql+pymysql:\\/\\/glance:${GLANCE_PASS}@controller\\/glance/" \
    -e 's/^.auth_uri.=.*/auth_uri = http:\\/\\/controller:5000\\nauth_url = http:\\/\\/controller:35357/' \
    -e 's/^.memcached_servers.=.*/memcached_servers = controller:11211/' \
    -e "s/^.auth_type.=.*/auth_type = password\\nproject_domain_name = default\\nuser_domain_name = default\\nproject_name = service\\nusername = glance\\npassword = $GLANCE_PASS/" \
    -e 's/^.flavor.=.*/flavor = keystone/' \
    -e 's/^.stores.=.*/stores = file,http/' \
    -e 's/^.default_store.=.*/default_store = file/' \
    -e 's/^.filesystem_store_datadir.=.*/filesystem_store_datadir = \\/var\\/lib\\/glance\\/images\\//' \
    /etc/glance/glance-api.conf
    #-e 's/\\(^sqlite_db.=.*\\)/#\\1/'
  sudo cp -npv /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.original
  sudo sed --in-place \
    -e "s/^#connection.=.*/connection = mysql+pymysql:\\/\\/glance:${GLANCE_PASS}@controller\\/glance/" \
    -e 's/^.*auth_uri.=.*/auth_uri = http:\\/\\/controller:5000\\nauth_url = http:\\/\\/controller:35357/' \
    -e 's/^.*memcached_servers.=.*/memcached_servers = controller:11211/' \
    -e "s/^.*auth_type.=.*/auth_type = password\\nproject_domain_name = default\\nuser_domain_name = default\\nproject_name = service\\nusername = glance\\npassword = $GLANCE_PASS/" \
    -e 's/^.*flavor.=.*/flavor = keystone/' \
    /etc/glance/glance-registry.conf
    #-e 's/\\(^sqlite_db.=.*\\)/#\\1/'
  sudo su -s /bin/sh -c "glance-manage db_sync" glance
  sudo service glance-registry restart
  sudo service glance-api restart

  ##########
  #Nova
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/nova-controller-install.html
  ##########
  NOVA_DBPASS="$DEFAULT_PASS"
  NOVA_PASS="$DEFAULT_PASS"

  . admin-openrc
  echo 'CREATE DATABASE nova_api; CREATE DATABASE nova;' \
    "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';" \
    "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';" \
    "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';" \
    "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';" \
    | mysql --user=root --password=$DEFAULT_PASS

  openstack user create --domain default --password $DEFAULT_PASS nova
  openstack role add --project service --user nova admin
  openstack service create --name nova --description "OpenStack Compute" compute
  openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\\\(tenant_id\\\)s
  openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\\\(tenant_id\\\)s
  openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\\\(tenant_id\\\)s
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler

  sudo cp -npv /etc/nova/nova.conf /etc/nova/nova.conf.original
  sed --in-place -E 's/^( )?enabled_apis( )?=.*/enabled_apis = osapi_compute,metadata/g' /etc/nova/nova.conf
  sudo sh -c "cat <<EOT >> /etc/nova/nova.conf
rpc_backend = rabbit
auth_strategy = keystone
my_ip = $IP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver

[api_database]
connection = mysql+pymysql://nova:$DEFAULT_PASS@controller/nova_api

[database]
connection = mysql+pymysql://nova:$DEFAULT_PASS@controller/nova

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = $NOVA_PASS
EOT"

  sudo sh -c 'cat <<EOT >> /etc/nova/nova.conf
[vnc]
vncserver_listen = \\\$my_ip
vncserver_proxyclient_address = \\\$my_ip

[glance]
api_servers = http://controller:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp
EOT'

  sudo su -s /bin/sh -c "nova-manage api_db sync" nova
  sudo su -s /bin/sh -c "nova-manage db sync" nova

  sudo service nova-api restart
  sudo service nova-consoleauth restart
  sudo service nova-scheduler restart
  sudo service nova-conductor restart
  sudo service nova-novncproxy restart

  ##########
  #Neutron
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/neutron-controller-install.html
  ##########
  NEUTRON_DBPASS="$DEFAULT_PASS"
  NEUTRON_PASS="$DEFAULT_PASS"
  METADATA_SECRET=$(openssl rand -hex 10)

  . admin-openrc

  echo "CREATE DATABASE neutron;"\
    "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';" \
    "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';" \
    | mysql --user=root --password=$DEFAULT_PASS

  openstack user create --domain default --password $NEUTRON_PASS neutron
  openstack role add --project service --user neutron admin
  openstack service create --name neutron --description "OpenStack Networking" network
  openstack endpoint create --region RegionOne network public http://controller:9696
  openstack endpoint create --region RegionOne network internal http://controller:9696
  openstack endpoint create --region RegionOne network admin http://controller:9696

  #http://docs.openstack.org/mitaka/install-guide-ubuntu/neutron-controller-install-option2.html

  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent

  sudo cp -npv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
  sudo sed --in-place \
    -e "s/^connection.=.*/connection = mysql+pymysql:\\/\\/neutron:${NEUTRON_PASS}@controller\\/neutron/" \
    -e 's/^.*core_plugin =.*/core_plugin = ml2/' \
    -e 's/^.*service_plugins =.*/service_plugins = router/' \
    -e 's/^.*allow_overlapping_ips =.*/allow_overlapping_ips = True/' \
    -e 's/^.*rpc_backend =.*/rpc_backend = rabbit/' \
    -e 's/^.*rabbit_host =.*/rabbit_host = controller/' \
    -e 's/^.*rabbit_userid =.*/rabbit_userid = openstack/' \
    -e "s/^.*rabbit_password =.*/rabbit_password = $RABBIT_PASS/" \
    -e 's/^.*auth_strategy =.*/auth_strategy = keystone/' \
    -e "s/^.*memcached_servers.=.*/memcached_servers = controller:11211\\nauth_type = password\\nproject_domain_name = default\\nuser_domain_name = default\\nproject_name = service\\nusername = neutron\\npassword = $NEUTRON_PASS/" \
    -e 's/^.*notify_nova_on_port_status_changes =.*/notify_nova_on_port_status_changes = True/' \
    -e 's/^.*notify_nova_on_port_data_changes =.*/notify_nova_on_port_data_changes = True/' \
    -e "s/^.*auth_url.=.*/auth_url = http:\\/\\/controller:35357\\nauth_type = password\\nproject_domain_name = default\\nuser_domain_name = default\\nregion_name = RegionOne\\nproject_name = service\\nusername = nova\\npassword = $NOVA_PASS/" \
    -e 's/^.*auth_uri.=.*/auth_uri = http:\\/\\/controller:5000\\nauth_url = http:\\/\\/controller:35357/' \
    /etc/neutron/neutron.conf

  sudo cp -npv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.original
  sudo sed --in-place \
    -e 's/^.*type_drivers =.*/type_drivers = flat,vlan,vxlan/' \
    -e 's/^.*tenant_network_types =.*/tenant_network_types = vxlan/' \
    -e 's/^.*mechanism_drivers =.*/mechanism_drivers = linuxbridge,l2population/' \
    -e 's/^#extension_drivers =.*/extension_drivers = port_security/' \
    -e 's/^.*flat_networks =.*/flat_networks = provider/' \
    -e 's/^.*vni_ranges =.*/vni_ranges = 1:1000/' \
    -e 's/^#enable_ipset =.*/enable_ipset = True/' \
  /etc/neutron/plugins/ml2/ml2_conf.ini

  sudo cp -npv /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.original
  sudo sed --in-place \
    -e 's/^.*physical_interface_mappings =.*/physical_interface_mappings = provider:eth1/' \
    -e 's/^.*enable_vxlan =.*/enable_vxlan = True/' \
    -e "s/^.*local_ip =.*/local_ip = $IP/" \
    -e 's/^.*l2_population =.*/l2_population = True/' \
    -e 's/^.*enable_security_group =.*/enable_security_group = True/' \
    -e 's/^.*firewall_driver =.*/firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver/' \
  /etc/neutron/plugins/ml2/linuxbridge_agent.ini

  sudo cp -npv /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.original
  sudo sed --in-place \
    -e 's/^.*interface_driver =.*/interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver/' \
    -e 's/^.*external_network_bridge =.*/external_network_bridge =/' \
  /etc/neutron/l3_agent.ini

  sudo sed --in-place \
    -e 's/^.*interface_driver =.*/interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver/' \
    -e 's/^.*dhcp_driver =.*/dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq/' \
    -e 's/^#enable_isolated_metadata =.*/enable_isolated_metadata = True/' \
  /etc/neutron/dhcp_agent.ini

  sudo sed --in-place \
    -e 's/^.*nova_metadata_ip =.*/nova_metadata_ip = controller/' \
    -e "s/^.*metadata_proxy_shared_secret =.*/metadata_proxy_shared_secret = $METADATA_SECRET/" \
    /etc/neutron/metadata_agent.ini
  sudo sh -c "cat <<EOT >> /etc/nova/nova.conf

[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $NEUTRON_PASS

service_metadata_proxy = True
metadata_proxy_shared_secret = $METADATA_SECRET
EOT"
  sudo su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  sudo service nova-api restart
  service neutron-server restart
  sudo service neutron-linuxbridge-agent restart
  sudo service neutron-dhcp-agent restart
  sudo service neutron-metadata-agent restart
  sudo service neutron-l3-agent restart

  ##########
  #Horizon
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/horizon-install.html
  ##########
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install openstack-dashboard

  sudo cp -npv /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.original
  sudo sed --in-place \
    -e 's/^OPENSTACK_HOST =.*/OPENSTACK_HOST = "controller"/' \
    -e 's/^.*OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT =.*/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/' \
    -e 's/^.*OPENSTACK_KEYSTONE_DEFAULT_DOMAIN =.*/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"/' \
    -e 's/^.*OPENSTACK_KEYSTONE_DEFAULT_ROLE =.*/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"/' \
  /etc/openstack-dashboard/local_settings.py

  sudo sh -c "echo SESSION_ENGINE = \\\'django.contrib.sessions.backends.cache\\\' > /etc/openstack-dashboard/local_settings.py"
  sudo sh -c 'cat <<EOT >> /etc/openstack-dashboard/local_settings.py
OPENSTACK_API_VERSIONS = {
  "identity": 3,
  "image": 2,
  "volume": 2,
}
EOT'
  sudo service apache2 reload
SCRIPT

$compute1 = <<SCRIPT
  DEFAULT_PASS='vagrant'
  RABBIT_PASS="$DEFAULT_PASS"
  NEUTRON_PASS="$DEFAULT_PASS"
  IP_CONTROLLER='10.0.2.11'
  IP_COMPUTE1='10.0.2.31'

  [ $(hostname) == 'controller' ] && IP="$IP_CONTROLLER"
  [ $(hostname) == 'compute1' ] && IP="$IP_COMPUTE1"

  export DEBIAN_FRONTEND=noninteractive

  ##########
  #Nova
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/nova-compute-install.html
  ##########

  sudo cp -npv /etc/nova/nova.conf /etc/nova/nova.conf.original
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install nova-compute
  sudo sh -c "cat <<EOT >> /etc/nova/nova.conf
rpc_backend = rabbit
auth_strategy = keystone
my_ip = $IP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver

[api_database]
connection = mysql+pymysql://nova:$DEFAULT_PASS@ontroller/nova_api

[database]
connection = mysql+pymysql://nova:$DEFAULT_PASS@controller/nova

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = $DEFAULT_PASS
EOT"

  sudo sh -c 'cat <<EOT >> /etc/nova/nova.conf
[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = \\\$my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[glance]
api_servers = http://controller:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp
EOT'

  [ $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 ] && sudo sed --in-place 's/^virt_type.*/virt_type = qemu/' /etc/nova/nova-compute.conf
  sudo service nova-compute restart

  ##########
  #Neutron
  #http://docs.openstack.org/mitaka/install-guide-ubuntu/neutron-compute-install.html
  ##########
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install neutron-linuxbridge-agent

  cp -npv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
  sudo sed --in-place \
    -e 's/^.*rpc_backend =.*/rpc_backend = rabbit/' \
    -e 's/^.*rabbit_host =.*/rabbit_host = controller/' \
    -e 's/^.*rabbit_userid =.*/rabbit_userid = openstack/' \
    -e "s/^.*rabbit_password =.*/rabbit_password = $RABBIT_PASS/" \
    -e 's/^.*auth_strategy =.*/auth_strategy = keystone/' \
    -e "s/^.*memcached_servers.=.*/memcached_servers = controller:11211\\nauth_type = password\\nproject_domain_name = default\\nuser_domain_name = default\\nproject_name = service\\nusername = neutron\\npassword = $NEUTRON_PASS/" \
    -e 's/^.*auth_url.=.*/auth_url = http:\\/\\/controller:35357/' \
    -e 's/^.*auth_uri.=.*/auth_uri = http:\\/\\/controller:5000\\nauth_url = http:\\/\\/controller:35357/' \
    /etc/neutron/neutron.conf

  sudo cp -npv /etc/nova/nova.conf /etc/nova/nova.conf.original
  sudo sh -c "cat <<EOT >> /etc/nova/nova.conf

[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $NEUTRON_PASS
EOT"

  sudo cp -npv /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.original
  sudo sed --in-place \
    -e 's/^.*physical_interface_mappings =.*/physical_interface_mappings = provider:eth1/' \
    -e 's/^.*enable_vxlan =.*/enable_vxlan = True/' \
    -e "s/^.*local_ip =.*/local_ip = $IP/" \
    -e 's/^.*l2_population =.*/l2_population = True/' \
    -e 's/^.*enable_security_group =.*/enable_security_group = True/' \
    -e 's/^.*firewall_driver =.*/firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver/' \
  /etc/neutron/plugins/ml2/linuxbridge_agent.ini

  sudo service nova-compute restart
  sudo service neutron-linuxbridge-agent restart
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = "DIGITALR00TS/ubuntu1404"
  config.vm.define "controller", primary: true, autostart: false do |controller|
    controller.vm.hostname = "controller"
    config.vm.network "forwarded_port", guest: 80, host: 9001
    controller.vm.network "private_network", ip: "10.10.0.11", netmask: "24", virtualbox__intnet: true, auto_config: false
    controller.vm.network "private_network", ip: "10.0.0.11", netmask: "24", virtualbox__intnet: true
    controller.vm.provision "shell", path: "https://github.com/digitalr00ts/openstack-bs/raw/master/run.sh", args: "'controller'"
  end

  config.vm.define "compute1", autostart: false do |compute1|
    compute1.vm.hostname = "compute1"
    compute1.vm.network "private_network", ip: "10.10.0.31", netmask: "24", virtualbox__intnet: true, auto_config: false
    compute1.vm.network "private_network", ip: "10.0.0.31", netmask: "24", virtualbox__intnet: true
    compute1.vm.provision "shell", path: "https://github.com/digitalr00ts/openstack-bs/raw/master/run.sh", args: "'compute'"
  end
  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
  #   vb.gui = true
    vb.memory = "4096"
  end

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  config.vm.provision "shell", inline: "sudo sed --in-place '/127\\.0\\.1\\./d' /etc/hosts"
  #config.vm.provision "shell" do |s|
  #  s.inline = $base
  #  s.env do |v|
  #    v.asdf = "hello"
  #  end
  #end
end
