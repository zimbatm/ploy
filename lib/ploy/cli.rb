require 'ploy'
require 'thor'

module Ploy
  # http://whatisthor.com/
  class CLI < Thor
    class ConfigurationError < Ploy::Errors::Error; end

    desc "init", "Adds default slugify and install scripts in your project"
    def init
      require 'ploy/app'
      require 'ploy-scripts'

      app = App.find(Dir.pwd)
      raise PloyError, "Project not found" unless app

      system("cp -rv #{PloyScripts.bootstrap_dir}/* #{app.root}")
    end

    desc "account", "Gets account informations"
    def account
      require 'ploy/client'
      host = Ploy.config.host
      token = Ploy.config.token
      raise ConfigurationError, "Unknown host" unless host
      raise ConfigurationError, "Unknown token" unless token

      client = Client.new(host: host, auth: ":#{token}")
      p client.get_account
    end

    desc "version", "Prints the version of ploy"
    def version
      require 'ploy/version'
      puts "Ploy v#{Ploy::VERSION}"
    end

  end
end
