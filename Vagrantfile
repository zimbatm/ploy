# -*- mode: ruby -*-
# # vi: set ft=ruby :
#
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-13.04-server-amd64"
  # config.vm.box_url =
  #   "https://s3.amazonaws.com/mediacore-public/boxes/ec2-precise64.box"
  config.vm.hostname = "ployd"
  # Docker
  config.vm.network :forwarded_port, guest: 4243, host: 4243
  # API
  config.vm.network :forwarded_port, guest: 5000, host: 5000
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
  install ruby1.9.1 ruby1.9.1-dev build-essential
fi

if ! has git ; then
  install git
fi

if ! has redis-server ; then
  install redis-server
fi

if ! has beanstalkd ; then
  install beanstalkd
  sed -e 's/#START=yes/START=yes/g' -i /etc/default/beanstalkd
  service beanstalkd start
fi

if ! has bundler ; then
  install libsqlite3-dev libcurl4-openssl-dev libxslt-dev libxml2-dev
  sudo gem install bundler --no-ri --no-rdoc
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

SCRIPT
end

