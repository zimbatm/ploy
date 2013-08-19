require File.expand_path('../boot', __FILE__)
require 'app/api'
require 'ploy'
require 'beanstalkd_view'
require 'lines/rack_logger'

use Lines::RackLogger
Lines::RackLogger.silence_common_logger!

if ENV['RACK_HOST']
  require 'rack/ssl'
  use Rack::SSL, host: ENV['RACK_HOST']
end

map '/bs' do
  run BeanstalkdView::Server
end

map '/doc' do
  use Rack::Static, urls: ['/'], index: 'index.html', root: File.join(Ploy.data_dir, 'swagger-ui')
end

run App::Root
