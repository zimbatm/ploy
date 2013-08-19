require 'ploy/cli/helpers'

module Ploy
  module CLI
    class Build < Thor
      include Helpers
      class_option :app_name, banner: 'APP_NAME', default: CLI.app_name

      desc "create", "Builds a slug"
      def create(commit_id=CLI.app_commit_id, branch=CLI.app_branch)
        resp =  client.post_new_build(options[:app_name], commit_id, branch)

        display "----build--->  #{resp['build']['id']}"
      end

      desc "list", "Lists the build jobs"
      def list
        resp = client.get_build_list(options[:app_name])

        builds = resp['builds'].map do |build|
          {
            'id'          => build['id'],
            'created_at'  => build['created_at'],
            'commit_id'   => build['commit_id'][0..6], 
            'branch'      => build['branch'],
            'state'       => build['state'],
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
