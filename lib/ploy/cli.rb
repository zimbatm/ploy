require 'ploy'
require 'thor'
require 'pp'

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

    desc "ploy_config", "Infos"
    def ploy_config
      pp Ploy.config
    end

    desc "account", "Gets account informations"
    def account
      pp client.get_account
    end

    desc "providers", "Gets account-linked providers"
    def providers
      pp client.get_providers
    end

    desc "version", "Prints the version of ploy"
    def version
      require 'ploy/version'
      puts "Ploy v#{Ploy::VERSION}"
    end

    protected

    def client
      return @client if @client
      require 'ploy/client'
      host = Ploy.config.host
      token = Ploy.config.token
      raise ConfigurationError, "Unknown host" unless host
      raise ConfigurationError, "Unknown token" unless token
      @client = Client.new(host: host, auth: ":#{token}")
    end

  end
end
