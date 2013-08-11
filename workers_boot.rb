require File.expand_path('../app/boot', __FILE__)
require 'app/workers'

App::BuildWorker.new.run
