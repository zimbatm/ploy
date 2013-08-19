require 'thor'
require 'pp'

require 'ploy/cli/app'
require 'ploy/cli/build'
require 'ploy/cli/helpers'
require 'ploy/cli/standalone'
require 'ploy/version'

module Ploy
  module CLI
    def self.start(args)
      Main.start(args)
    end

    # http://whatisthor.com/
    class Main < Thor
      include Helpers

      def self.dispatch(meth, given_args, given_opts, config)
        super
      rescue Ploy::Error => ex
        p ex
      end

      desc "init", "Adds default slugify and install scripts in your project"
      def init
        raise PloyError, "Project not found" unless CLI.app_root

        system("cp -rv #{Ploy.bootstrap_dir}/* #{CLI.app_root}")
      end

      desc "config", "Ploy configuration"
      def config
        puts "Ploy::Config"
        puts CLI.config
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

      desc "app SUBCOMMAND ...ARGS", "manage the app"
      subcommand "app", App

      desc "build SUBCOMMAND ...ARGS", "builds slugs"
      subcommand "build", Build

      desc "standalone SUBCOMMAND ...ARGS", "local commands"
      subcommand "standalone", Standalone

      desc "version", "Prints the version of ploy"
      def version
        require 'ploy/version'
        puts "Ploy v#{Ploy::VERSION}"
      end
    end
  end
end

