# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "DIGITALR00TS/ubuntu1404"

  config.vm.define "controller", primary: false, autostart: false do |controller|
    controller.vm.hostname = "controller"
    config.vm.network "forwarded_port", guest: 80, host: 9001
    controller.vm.network "private_network", ip: "10.10.0.11", netmask: "24", virtualbox__intnet: true, auto_config: false
    controller.vm.network "private_network", ip: "10.0.0.11", netmask: "24", virtualbox__intnet: true
  end

  config.vm.define "compute1", autostart: false do |compute1|
    compute1.vm.hostname = "compute1"
    compute1.vm.network "private_network", ip: "10.10.0.31", netmask: "24", virtualbox__intnet: true, auto_config: false
    compute1.vm.network "private_network", ip: "10.0.0.31", netmask: "24", virtualbox__intnet: true
  end

  config.vm.synced_folder "salt/", "/srv/salt/"

  config.vm.provision :shell do |shell|
    shell.inline = "sudo rmdir /etc/salt/minion.d ; sudo ln -s /srv/salt/minion.d /etc/salt/minion.d"
  end

  config.vm.provision :salt do |salt|
    salt.masterless = true
  end

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

end
