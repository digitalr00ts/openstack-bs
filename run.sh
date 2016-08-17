#!/usr/bin/env bash

if [ "$1" == 'compute' ] || [ "$1" == 'controller' ]; then
  NODE_TYPE="$1"
fi

if [ -z $NODE_TYPE ]; then
  echo "Runs scripts based on node type specified."
  echo "Usage: $(basename "$0") <compute|controller>"
  exit 1
fi

echo 'Checking for curl'
which curl >/dev/null
if [ $? ]; then
  echo 'ERROR: curl command not found.' >&2
  sudo apt-get --force-yes --assume-yes install curl || exit $?
fi

echo 'Loading config.ini'
[ ! -f ./config.ini ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/config.ini
. ./config.ini

echo 'Running base.sh'
[ ! -f ./base.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/base.sh && chmod +x ./base.sh
./base.sh

[ ! -f ./ntp.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/ntp.sh && chmod +x ./ntp.sh
./ntp.sh

if [ "$NODE_TYPE" == 'controller' ]; then

  [ ! -f ./environment.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/controller/environment.sh && chmod +x ./environment.sh
  ./environment.sh

  [ ! -f ./keystone.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/controller/keystone.sh && chmod +x ./keystone.sh
  ./keystone.sh

  [ ! -f ./glance.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/controller/glance.sh && chmod +x ./glance.sh
  ./glance.sh

  [ ! -f ./nova.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/controller/nova.sh && chmod +x ./nova.sh
  ./nova.sh

  [ ! -f ./neutron.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/controller/neutron.sh && chmod +x ./neutron.sh
  ./neutron.sh

  [ ! -f ./neutron.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/controller/horizon.sh && chmod +x ./horizon.sh
  ./horizon.sh

elif [ "$NODE_TYPE" == 'compute' ]; then

  [ ! -f ./compute/nova.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/compute/nova.sh && chmod +x ./nova.sh
  ./nova.sh

  [ ! -f ./compute/neutron.sh ] && curl -sSLO https://github.com/digitalr00ts/openstack-bs/raw/master/compute/neutron.sh && chmod +x ./neutron.sh
  ./neutron.sh

fi
