require File.expand_path('../app/boot', __FILE__)
require 'app/api'
require 'lines/rack_logger'

use Lines::RackLogger
Lines::RackLogger.silence_common_logger!

if ENV['RACK_HOST']
  require 'rack/ssl'
  use Rack::SSL, host: ENV['RACK_HOST']
end

run App::API
