require 'ploy'
require 'thor'
require 'pp'

module Ploy
  # http://whatisthor.com/
  class CLI < Thor
    module ClientHelper
      class ConfigurationError < Ploy::Errors::Error; end

      protected

      def client
        return @client if @client
        require 'ploy/client'
        host = Ploy.config.host
        token = Ploy.config.token
        raise ConfigurationError, "Unknown host" unless host
        raise ConfigurationError, "Unknown token" unless token
        @client = Client.new(host: host, token: token)
      end
    end
    include ClientHelper

    desc "init", "Adds default slugify and install scripts in your project"
    def init
      require 'ploy-scripts'

      raise PloyError, "Project not found" unless Ploy.config.app_root

      system("cp -rv #{PloyScripts.bootstrap_dir}/* #{Ploy.config.app_root}")
    end

    desc "config", "Ploy configuration"
    def config
      pp Ploy.config
    end

    desc "account", "Gets account informations"
    def account
      pp client.get_account
    end

    desc "apps", "Gets applications"
    def apps
      pp client.get_apps
    end

    desc "providers", "Gets account-linked providers"
    def providers
      pp client.get_providers
    end

    class App < Thor
      include ClientHelper
      class_option :app, banner: 'APP_NAME', default: Ploy.config.app_name
      desc "create", "New app"
      def create
        pp client.post_apps(options[:app])
      end

      desc "info", "Info on the app"
      def info
        pp client.get_app(options[:app])
      end

      desc "slugs", "Slugs of an app"
      def slugs
        pp client.get_slugs(options[:app])
      end

      desc "targets", "Targets of an app"
      def targets
        pp client.get_targets(options[:app])
      end
    end

    desc "app SUBCOMMAND ...ARGS", "manage the app"
    subcommand "app", App

    desc "version", "Prints the version of ploy"
    def version
      require 'ploy/version'
      puts "Ploy v#{Ploy::VERSION}"
    end
  end
end
