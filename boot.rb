# Setups the environment

libdir = File.expand_path('../lib', __FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

# ENV["BUNDLE_GEMFILE"] = File.expand_path('../../Gemfile', __FILE__)
# Bundler.setup

require 'ploy'
