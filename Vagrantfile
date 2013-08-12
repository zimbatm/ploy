# -*- mode: ruby -*-
# # vi: set ft=ruby :
#
Vagrant.configure("2") do |config|
  config.vm.box = "raring64"
  config.vm.box_url =
    "http://cloud-images.ubuntu.com/raring/current/raring-server-cloudimg-vagrant-amd64-disk1.box"
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
  sudo gem install bundler --no-ri --no-rdoc
fi

# See: http://docs.docker.io/en/latest/installation/ubuntulinux/#ufw
if has ufw ; then
  dpkg -r ufw
fi

APP_USER=vagrant
mkdir -p /app/deploys
mkdir -p /app/data
chown $APP_USER:$APP_USER /app/data
rm -rf /app/deploys/deploy_id
ln -s /vagrant /app/deploys/deploy_id
rm -rf /app/current
ln -s /app/deploys/deploy_id /app/current

chmod 777 /var/run/docker.sock

echo alias "app='cd /app/current'" > /home/vagrant/.bash_aliases

SCRIPT
end

