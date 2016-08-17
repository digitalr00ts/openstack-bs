#!/usr/bin/env bash
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
vncserver_proxyclient_address = \$my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[glance]
api_servers = http://controller:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp
EOT'

[ $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 ] && sudo sed --in-place 's/^virt_type.*/virt_type = qemu/' /etc/nova/nova-compute.conf

sudo service nova-compute restart
