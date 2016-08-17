# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "DIGITALR00TS/ubuntu1404"
  config.vm.define "controller", primary: true, autostart: false do |controller|
    controller.vm.hostname = "controller"
    config.vm.network "forwarded_port", guest: 80, host: 9001
    controller.vm.network "private_network", ip: "10.10.0.11", netmask: "24", virtualbox__intnet: true, auto_config: false
    controller.vm.network "private_network", ip: "10.0.0.11", netmask: "24", virtualbox__intnet: true
    controller.vm.provision "shell", path: "https://github.com/digitalr00ts/openstack-bs/raw/master/run.sh", args: "'controller'"
  end

  config.vm.define "compute1", autostart: false do |compute1|
    compute1.vm.hostname = "compute1"
    compute1.vm.network "private_network", ip: "10.10.0.31", netmask: "24", virtualbox__intnet: true, auto_config: false
    compute1.vm.network "private_network", ip: "10.0.0.31", netmask: "24", virtualbox__intnet: true
    compute1.vm.provision "shell", path: "https://github.com/digitalr00ts/openstack-bs/raw/master/run.sh", args: "'compute'"
  end
  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
  #   vb.gui = true
    vb.memory = "4096"
  end

  config.vm.provision "shell", inline: "sudo sed --in-place '/127\\.0\\.1\\./d' /etc/hosts"
end
