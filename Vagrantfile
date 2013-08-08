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
set -e

has() {
  type "$1" &>/dev/null
}

updated=
install() {
  if [ -z "$updated" ]; then
    apt-get update -qq
    updated=yes
  fi
  DEBIAN_FRONTEND=noninteractive apt-get install -q -y $@
}

if ! has add-apt-repository ; then
  install python-software-properties
fi

if ! has docker ; then
  add-apt-repository -y ppa:dotcloud/lxc-docker
  updated=
  install lxc-docker
fi

if ! has ruby ; then
  install ruby1.9.1 ruby1.9.1-dev build-essential
fi
SCRIPT
end

