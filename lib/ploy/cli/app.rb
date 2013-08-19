require 'thor'
require 'pp'

require 'ploy/cli/helpers'
require 'ploy/cli/config'

module Ploy
  module CLI
    class App < Thor
      include Helpers
      class_option :app, banner: 'APP_NAME', default: CLI.app_name
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
        resp =  client.get_app_slugs(options[:app])
        slugs = resp['slugs'].map do |slug|
          {
            'id' => slug['id'],
            'commit_id' => slug['commit_id'][0..6],
            'branch' => slug['branch'],
            'checksum' => slug['checksum'],
            'url' => slug['url'],
          }
        end

        display_table(
          slugs,
          %w( id commit_id branch checksum url),
          ["ID", "Commit", "Branch", "Checksum", "Url"]
        )

      end

      desc "targets", "Targets of an app"
      def targets
        pp client.get_app_targets(options[:app])
      end

      desc "deploy", "Deploys"
      def deploy(env='staging')
        pp client.post_app_deploy(options[:app], CLI.app_commit_id, env)
      end
    end
  end
end
