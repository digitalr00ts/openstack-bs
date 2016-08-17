#!/usr/bin/env bash
#TO DO
#NTP
#http://docs.openstack.org/mitaka/install-guide-ubuntu/environment-ntp.html
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install chrony
