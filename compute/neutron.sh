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
  -e "s/^.*memcached_servers.=.*/memcached_servers = controller:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS/" \
  -e 's/^.*auth_url.=.*/auth_url = http:\/\/controller:35357/' \
  -e 's/^.*auth_uri.=.*/auth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/' \
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
