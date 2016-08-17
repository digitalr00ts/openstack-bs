#!/usr/bin/env bash
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
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s
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
vncserver_listen = \$my_ip
vncserver_proxyclient_address = \$my_ip

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
