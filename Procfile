beanstalkd: beanstalkd -b var -V
web: bundle exec puma -t 16:16 -p $PORT config.ru
worker: bundle exec ruby workers_boot.rb
