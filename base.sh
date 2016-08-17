#!/usr/bin/env bash
echo 'apt-get update' ; sudo apt-get update -qqy
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install vim
sudo apt-get --force-yes --assume-yes purge resolvconf

sudo sh -c "cat <<EOT >> /etc/network/interfaces
auto $PROV_ETH
iface $PROV_ETH inet manual
up ip link set dev \$IFACE up
down ip link set dev \$IFACE down
EOT"

sudo sh -c "cat <<EOT >> /etc/hosts

# controller
$IP_CONTROLLER		controller
# compute1
$IP_COMPUTE1		compute1
EOT"

#Packages
#http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-packages.html
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install software-properties-common
sudo add-apt-repository --yes cloud-archive:mitaka
echo 'apt-get update' ; sudo apt-get -qqy update && \
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes dist-upgrade
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install python-openstackclient
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install python-pymysql
