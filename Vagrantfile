# -*- mode: ruby -*-
# # vi: set ft=ruby :
#
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-13.04-server-amd64"
  config.vm.box_url =
    "http://panda-slugs.s3.amazonaws.com/ubuntu-13.04-server-amd64.box"
  config.vm.hostname = "ployd"
  config.vm.network :forwarded_port, guest: 4243, host: 4243 # Docker
  config.vm.network :forwarded_port, guest: 5000, host: 5000 # API
  config.ssh.forward_agent = true
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
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
  install software-properties-common
fi

if ! has docker ; then
  add-apt-repository -y ppa:dotcloud/lxc-docker
  updated=
  install lxc-docker
fi

if ! has ruby ; then
  install ruby1.9.1
fi

if ! has git ; then
  install git
fi

if ! has beanstalkd ; then
  install beanstalkd
  sed -e 's/#START=yes/START=yes/g' -i /etc/default/beanstalkd
  service beanstalkd start
fi

if ! has bundle ; then
  install ruby1.9.1-dev libsqlite3-dev libcurl4-openssl-dev libxslt-dev libxml2-dev build-essential
  gem install bundler --no-ri --no-rdoc
fi

if ! has foreman ; then
  gem install foreman --no-ri --no-rdoc
fi

# See: http://docs.docker.io/en/latest/installation/ubuntulinux/#ufw
if has ufw ; then
  dpkg -r ufw
fi

if ! grep "cgroup_enable" /etc/default/grub &>/dev/null ; then
  sed -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"/g' -i /etc/default/grub
  update-grub
fi

# Fake deploy
rm -rf /app
ln -s /vagrant /app

# Allow docker access from the app
chmod 777 /var/run/docker.sock

# Setup aliases
echo alias "be='bundle exec'" >> /home/vagrant/.bash_aliases

SCRIPT
end

