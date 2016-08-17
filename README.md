# openstack-bs
OpenStack bootstrap scripts

Openstack Mitaka, build on Ubuntu 14.04
(2 node cluster with self service networks)

## Requirements
  * [Vagrant](https://www.vagrantup.com/)
  * [KVM](http://www.linux-kvm.org/) or [VirtualBox](https://www.virtualbox.org)
  * 6GB of RAM for virtual machines
  * 16GB of HD space

## Run
```
curl -LO https://github.com/digitalr00ts/openstack-bs/raw/master/Vagrantfile
vagrant up controller && vagrant up compute1```
