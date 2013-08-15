require 'thor'

require 'ploy'
require 'ploy/cli/helpers'

module Ploy
  module CLI
    class Standalone < Thor
      desc "build", "Runs a local vagrant box to build the project. Only one build at a time"
      def build
        app_basename = CLI.config.app_basename
        hostname = app_basename + '-build'
        release_id = [
          app_basename,
          Time.now.to_i,
          CLI.config.app_branch,
          #CLI.config.app_commit_count,
          CLI.config.app_short_commit_id
        ].join('-')
        out = Ploy.gen_vagrantfile(hostname, release_id)

        vagrant_dir = File.join(CLI.config.app_root, '.ploy', hostname)

        FileUtils.mkdir_p vagrant_dir
        File.open(vagrant_dir + '/Vagrantfile', 'w') do |f|
          f.write out
        end

        # FIXME: only provision if the box is already up
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
          aws_access_key_id:      CLI.config.aws_access_key,
          aws_secret_access_key:  CLI.config.aws_secret_key,
        )

        bucket = s3.directories.get(CLI.config.aws_bucket)
        p [:s3_bucket, bucket]

        object_path = "slugs/#{CLI.config.app_name}/#{File.basename(path)}"

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
          aws_access_key_id:      CLI.config.aws_access_key,
          aws_secret_access_key:  CLI.config.aws_secret_key,
        )

        server = ec2.servers.get(instance_id)
        server.username = 'ubuntu'
        server.private_key = File.read(
          File.expand_path CLI.config.aws_private_key_path
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
          aws_access_key_id:      CLI.config.aws_access_key,
          aws_secret_access_key:  CLI.config.aws_secret_key,
        )
        server = ec2.servers.get(instance_id)
        command = "ssh -i #{CLI.config.aws_private_key_path} ubuntu@#{server.dns_name}"
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
  end
end
