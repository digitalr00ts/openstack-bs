#!/usr/bin/env bash

if [ "$1" == 'compute' ] || [ "$1" == 'controller' ]; then
  NODE_TYPE="$1"
fi

if [ -z $NODE_TYPE ]; then
  echo "Runs scripts based on node type specified."
  echo "Usage: $(basename "$0") <compute|controller>"
  exit 1
fi

which curl >/dev/null
if [ $? ]; then
  echo 'ERROR: curl command not found.' >&2
  sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes install curl || exit $?
fi

echo 'Loading config.ini'
[ ! -f ./config.ini ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/master/config.ini
. config.ini

echo 'Running base.sh'
[ ! -f ./base.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/master/base.sh && chmod +x base.sh
./base.sh

if [ "$NODE_TYPE" == 'controller' ]; then
  mkdir -p controller

  [ ! -f ./controller/environment.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/controller/environment.sh && chmod +x controller/environment.sh
  ./controller/environment.sh

  [ ! -f ./controller/keystone.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/controller/keystone.sh && chmod +x controller/keystone.sh
  ./controller/keystone.sh

  [ ! -f ./controller/glance.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/controller/glance.sh && chmod +x controller/glance.sh
  ./controller/glance.sh

  [ ! -f ./controller/nova.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/controller/nova.sh && chmod +x controller/nova.sh
  ./controller/nova.sh

  [ ! -f ./controller/neutron.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/controller/neutron.sh && chmod +x controller/neutron.sh
  ./controller/neutron.sh

elif [ "$NODE_TYPE" == 'compute' ]; then
  mkdir -p compute

  [ ! -f ./compute/nova.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/compute/nova.sh && chmod +x compute/nova.sh
  ./compute/nova.sh

  [ ! -f ./compute/neutron.sh ] && curl --progress-bar -LO https://github.com/digitalr00ts/openstack-bs/raw/compute/neutron.sh && chmod +x compute/neutron.sh
  ./compute/neutron.sh

fi
