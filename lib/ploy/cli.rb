require 'ploy'
require 'ploy/errors'
require 'thor'
require 'pp'

module Ploy
  # http://whatisthor.com/
  class CLI < Thor
    #### Extensions ####

    module ClientHelper
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
    module HandleErrors
      protected

      def dispatch(meth, given_args, given_opts, config)
        super
      rescue error_handled? => ex
        p ex
      end

      def error_handled?
        $!.kind_of?(Ploy::Errors::Error) && $!
      end
    end
    extend HandleErrors

    desc "init", "Adds default slugify and install scripts in your project"
    def init
      raise PloyError, "Project not found" unless Ploy.config.app_root

      system("cp -rv #{Ploy.bootstrap_dir}/* #{Ploy.config.app_root}")
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
        pp client.get_app_slugs(options[:app])
      end

      desc "targets", "Targets of an app"
      def targets
        pp client.get_app_targets(options[:app])
      end

      desc "deploy", "Deploys"
      def deploy(env='staging')
        pp client.post_app_deploy(options[:app], Ploy.config.commit_id, env)
      end
    end

    desc "app SUBCOMMAND ...ARGS", "manage the app"
    subcommand "app", App

    desc "build", "Runs a local vagrant box to build the project. Only one build at a time"
    def build
      vagrant_dir = File.join(Ploy.data_dir, 'vagrant')
      ENV['PLOY_BUILD_SCRIPT'] = PloyScripts.build_script
      ENV['PLOY_APP_ROOT'] = Ploy.config.app_root
      Dir.chdir(vagrant_dir)
      exec("vagrant up")
    end

    desc "version", "Prints the version of ploy"
    def version
      require 'ploy/version'
      puts "Ploy v#{Ploy::VERSION}"
    end
  end
end
