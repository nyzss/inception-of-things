# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp-education/ubuntu-24-04"
  config.vm.box_version = "0.1.0"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 1
  end

 config.vm.define "okocaS" do |control|
          control.vm.hostname = "okocaS"
          control.vm.network "private_network", ip: "192.168.56.110"
          control.vm.provider "virtualbox" do |v|
              v.customize ["modifyvm", :id, "--name", "okocaS"]
          end
      control.vm.provision "shell", path: "scripts/server.sh"
  end


  config.vm.define "okocaSW" do |control|
      control.vm.hostname = "okocaSW"
      control.vm.network "private_network", ip: "192.168.56.111"
      control.vm.provider "virtualbox" do |v|
          v.customize ["modifyvm", :id, "--name", "okocaSW"]
      end
      control.vm.provision "shell", path: "scripts/server_worker.sh"
  end

end
