#!/usr/bin/env bash

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

sudo sh -c "echo SESSION_ENGINE = \'django.contrib.sessions.backends.cache\' >> /etc/openstack-dashboard/local_settings.py"
sudo sh -c 'cat <<EOT >> /etc/openstack-dashboard/local_settings.py
OPENSTACK_API_VERSIONS = {
"identity": 3,
"image": 2,
"volume": 2,
}
EOT'

sudo service apache2 reload
