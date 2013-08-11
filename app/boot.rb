$:.unshift File.expand_path('../..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

# ENV["BUNDLE_GEMFILE"] = File.expand_path('../../Gemfile', __FILE__)
# Bundler.setup

require 'ploy'
require 'app/config'
require 'app/models'
require 'app/workers'
