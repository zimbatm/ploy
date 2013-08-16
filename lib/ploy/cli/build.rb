require 'ploy/cli/helpers'

module Ploy
  module CLI
    class Build < Thor
      include Helpers
      class_option :app_name, banner: 'APP_NAME', default: CLI.config.app_name

      desc "create", "Builds a slug"
      def create(commit_id=CLI.config.app_commit_id, branch=CLI.config.app_branch)
        build =  client.post_new_build(options[:app_name], commit_id, branch)

        display "----build--->  #{build['id']}"
      end

      desc "list", "Lists the build jobs"
      def list
        builds = client.get_build_list(options[:app_name])

        builds.map! do |build|
          {
            'id' => build['id'],
            'created_at' => build['created_at'],
            'commit_id' => build['commit_id'][0..6], 
            'branch' => build['branch'],
            'state' => build['state'],
          }
        end

        display_table(
          builds,
          %w( id created_at commit_id branch state),
          ["ID", "Build Time", "Commit", "Branch", "State"]
        )
      end
      
      desc "logs", "Show the build logs"
      def logs(build_id)
        puts client.get_build_logs(options[:app_name], build_id)
      end
    end
  end
end