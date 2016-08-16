##########
#Neutron
#http://docs.openstack.org/mitaka/install-guide-ubuntu/neutron-controller-install.html
##########
NEUTRON_DBPASS="$DEFAULT_PASS"
NEUTRON_PASS="$DEFAULT_PASS"
METADATA_SECRET=$(openssl rand -hex 10)

. admin-openrc

echo "CREATE DATABASE neutron;" \
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
  -e "s/^connection.=.*/connection = mysql+pymysql:\/\/neutron:${NEUTRON_PASS}@controller\/neutron/" \
  -e 's/^.*core_plugin =.*/core_plugin = ml2/' \
  -e 's/^.*service_plugins =.*/service_plugins = router/' \
  -e 's/^.*allow_overlapping_ips =.*/allow_overlapping_ips = True/' \
  -e 's/^.*rpc_backend =.*/rpc_backend = rabbit/' \
  -e 's/^.*rabbit_host =.*/rabbit_host = controller/' \
  -e 's/^.*rabbit_userid =.*/rabbit_userid = openstack/' \
  -e "s/^.*rabbit_password =.*/rabbit_password = $RABBIT_PASS/" \
  -e 's/^.*auth_strategy =.*/auth_strategy = keystone/' \
  -e "s/^.*memcached_servers.=.*/memcached_servers = controller:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS/" \
  -e 's/^.*notify_nova_on_port_status_changes =.*/notify_nova_on_port_status_changes = True/' \
  -e 's/^.*notify_nova_on_port_data_changes =.*/notify_nova_on_port_data_changes = True/' \
  -e "s/^.*auth_url.=.*/auth_url = http:\/\/controller:35357\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nregion_name = RegionOne\nproject_name = service\nusername = nova\npassword = $NOVA_PASS/" \
  -e 's/^.*auth_uri.=.*/auth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/' \
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
  -e "s/^.*metadata_proxy_shared_secret =.*/metadata_proxy_shared_secret = $METADATA_SECRET/"
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
