# -*- mode: ruby -*-
# # vi: set ft=ruby :
#
Vagrant.configure("2") do |config|
  config.vm.box = "ec2-precise64"
  config.vm.box_url =
    "https://s3.amazonaws.com/mediacore-public/boxes/ec2-precise64.box"
  config.vm.hostname = "ployd"
  config.vm.network :forwarded_port, guest: 4243, host: 4243
  config.vm.provision :shell,
    inline: <<SCRIPT
if ! uname -a | grep 3.8.0 ; then
  apt-get update -qq
  apt-get install linux-image-generic-lts-raring
  apt-get install -q -y python-software-properties
  add-apt-repository -y ppa:dotcloud/lxc-docker
  apt-get update -qq
  apt-get install -q -y lxc-docker

  apt-get install -q -y ruby1.9.1-dev
  reboot
fi
SCRIPT
end
