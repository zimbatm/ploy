require File.expand_path('../boot', __FILE__)
require 'app/workers'

App::BuildWorker.new.run
