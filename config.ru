require File.expand_path('../app/boot', __FILE__)
require 'app/api'
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

run App::API
