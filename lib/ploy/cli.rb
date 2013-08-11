require 'ploy'
require 'ploy/config'
require 'ploy/errors'
require 'thor'
require 'pp'

module Ploy
  module CLI
    module HandleErrors
      protected

      def dispatch(meth, given_args, given_opts, config)
        super
      rescue Ploy::Error => ex
        p ex
      end
    end

    module ClientHelper
      include Ploy::Errors
      protected
      def client
        return @client if @client
        require 'ploy/client'
        host = Ploy.config.ploy_host
        token = Ploy.config.ploy_token
        raise ConfigurationError, "Unknown host" unless host
        raise ConfigurationError, "Unknown token" unless token
        @client = Client.new(host: host, token: token)
      end

      def display_table(objects, columns, headers)
        lengths = []
        columns.each_with_index do |column, index|
          header = headers[index]
          items = [header].concat(objects.map { |o| o[column].to_s })
          lengths << items.map { |i| i.to_s.length }.sort.last
        end
        lines = lengths.map {|length| "-" * length}
        lengths[-1] = 0 # remove padding from last column
        display_row headers, lengths
        display_row lines, lengths
        objects.each do |row|
          display_row columns.map { |column| row[column] }, lengths
        end
      end

      def display_row(row, lengths)
        row_data = []
        row.zip(lengths).each do |column, length|
          format = column.is_a?(Fixnum) ? "%#{length}s" : "%-#{length}s"
          row_data << format % column
        end
        display(row_data.join("  "))
      end

      def display(msg="", new_line=true)
        if new_line
          puts(msg)
        else
          print(msg)
          $stdout.flush
        end
      end

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
        pp client.post_app_deploy(options[:app], Ploy.config.app_commit_id, env)
      end
    end

    class Build < Thor
      include ClientHelper
      class_option :app_name, banner: 'APP_NAME', default: Ploy.config.app_name

      desc "create", "Builds a slug"
      def create(commit_id=Ploy.config.app_commit_id, branch=Ploy.config.app_branch)
        pp client.post_new_build(options[:app_name], commit_id, branch)
      end

      desc "list", "Lists the build jobs"
      def list
        builds = client.get_build_list(options[:app_name])

        builds.map! do |build|
          {
            'id' => build['id'],
            'commit_id' => build['commit_id'][0..6], 
            'branch' => build['branch'],
            'state' => build['state'],
          }
        end

        display_table(
          builds,
          %w( id commit_id branch state),
          ["ID", "Commit", "Branch", "State"]
        )
      end
      #alias ls list
    end

    class Local < Thor
      desc "build", "Runs a local vagrant box to build the project. Only one build at a time"
      def build
        require 'erb'
        app_basename = File.basename(Ploy.config.app_name)
        hostname = app_basename + '-build'
        build_script = Ploy.build_script
        release_id = [
          app_basename,
          Time.now.to_i,
          Ploy.config.app_branch,
          Ploy.config.app_commit_count,
          Ploy.config.app_short_commit_id
        ].join('-')

        template = ERB.new(File.read(File.join(Ploy.data_dir, 'Vagrantfile.erb')))
        out = template.result(binding)

        vagrant_dir = File.join(Ploy.config.app_root, '.ploy', hostname)

        FileUtils.mkdir_p vagrant_dir
        File.open(vagrant_dir + '/Vagrantfile', 'w') do |f|
          f.write out
        end

        Dir.chdir(vagrant_dir) do
          system("vagrant up")
          system("vagrant destroy")
        end
      end

      desc "push", "Pushes a slug to S3"
      def push(path)
        require_fog

        s3 = Fog::Storage.new(
          provider: 'AWS',
          aws_access_key_id:      Ploy.config.aws_access_key,
          aws_secret_access_key:  Ploy.config.aws_secret_key,
        )

        bucket = s3.directories.get(Ploy.config.aws_bucket)
        p [:s3_bucket, bucket]

        object_path = "slugs/#{Ploy.config.app_name}/#{File.basename(path)}"

        p [:checking, object_path]
        object = bucket.files.head(object_path)
        if object
          p [:already_uploaded, object]
          return object
        end

        p [:uploading, object]
        object = bucket.files.create(
          key: object_path,
          body: File.open(path)
        )
        p [:uploaded, object]
        object
      end

      ONE_WEEK_INTERVAL = (60 * 60 * 24 * 7)

      desc "deploy", "Deploys a slug on a machine"
      def deploy(path, config_path, instance_id)
        object = push(path)

        require 'net/scp'
        require 'net/ssh'

        slug_url = object.url(Time.now + ONE_WEEK_INTERVAL)
        p [:slug_url, slug_url]

        deploy_script = Ploy.gen_deploy_local slug_url, File.read(config_path)

        ssh_options = {
          auth_methods: ["publickey"]
        }

        ec2 = Fog::Compute.new(
          provider: 'AWS',
          aws_access_key_id:      Ploy.config.aws_access_key,
          aws_secret_access_key:  Ploy.config.aws_secret_key,
        )

        server = ec2.servers.get(instance_id)
        server.username = 'ubuntu'
        server.private_key = File.read(
          File.expand_path Ploy.config.aws_private_key_path
        )
        p [:server, server]

        server.wait_for{ sshable?(ssh_options) }

        p [:uploading_deploy_script, deploy_script]
        server.scp StringIO.new(deploy_script), 'deploy.sh', ssh_options
        p [:executing_deploy_script]
        # FIXME: Run the deploy is the background with nohup
        server.ssh("chmod +x deploy.sh && sudo ./deploy.sh", ssh_options) do |stdout, stderr|
          $stdout.write stdout unless stdout.empty?
          $stderr.write stderr unless stderr.empty?
        end
      end

      desc "ssh", "SSH into the server"
      def ssh(instance_id)
        require_fog
        ec2 = Fog::Compute.new(
          provider: 'AWS',
          aws_access_key_id:      Ploy.config.aws_access_key,
          aws_secret_access_key:  Ploy.config.aws_secret_key,
        )
        server = ec2.servers.get(instance_id)
        command = "ssh -i #{Ploy.config.aws_private_key_path} ubuntu@#{server.dns_name}"
        puts command
        exec command
      end

      protected

      def require_fog
        begin
          require 'fog'
        rescue LoadError
          puts "fog is missing. `gem install fog` to use that command"
          exit 1
        end
      end
    end

    # http://whatisthor.com/
    class Main < Thor
      #### Extensions ####

      include ClientHelper
      extend HandleErrors

      desc "init", "Adds default slugify and install scripts in your project"
      def init
        raise PloyError, "Project not found" unless Ploy.config.app_root

        system("cp -rv #{Ploy.bootstrap_dir}/* #{Ploy.config.app_root}")
      end

      desc "config", "Ploy configuration"
      def config
        puts "Ploy::Config"
        puts Ploy.config
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

      desc "local SUBCOMMAND ...ARGS", "local commands"
      subcommand "local", Local

      desc "version", "Prints the version of ploy"
      def version
        require 'ploy/version'
        puts "Ploy v#{Ploy::VERSION}"
      end
    end
  end
end
