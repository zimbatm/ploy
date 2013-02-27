require 'ploy'
require 'thor'

module Ploy
  # http://whatisthor.com/
  class CLI < Thor
    class ConfigurationError < Ploy::Errors::Error; end

    desc "build", "WIP: Create a build of your code using Vagrant"
    def build
      require 'vagrant'
      require 'vagrant/cli'
      require 'vagrant/util/platform'
      #project_root = Dir.pwd
      env = Vagrant::Environment.new(
        cwd: File.expand_path('../script', __FILE__),
        ui_class: $stdout.tty? ? Vagrant::UI::Colored : Vagrant::UI::Basic
      )
      env.load!
      env.cli('up', '--no-provision')
      # TODO: Setup some custom stuff here
      #p [:provisioners, env.config.vm.provisioners]
      env.cli('provision')
      env.cli('destroy')
    rescue Vagrant::Errors::VagrantError => e
      p e
      exit e.status_code if e.respond_to?(:status_code)
      exit 999 
    end

    desc "connect", "Connects to a remote url and configures your repo"
    def connect

    end

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
