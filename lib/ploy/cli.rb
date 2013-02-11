require 'thor'

module Ploy
  # http://whatisthor.com/
  class CLI < Thor
    desc "build", "Create a build of your code using Vagrant"
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

    desc "account", "Gets account informations"
    def account
      raise ConfigurationError unless Ploy.config.host
    end
  end
end
