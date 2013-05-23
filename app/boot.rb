$:.unshift File.expand_path('../..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'ploy'
require 'app/config'
require 'app/models'
require 'app/workers'
