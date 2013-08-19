require 'ploy/env_config'
require 'ploy/cli/errors'

module Ploy
  module CLI
    # Small wrapper class around the command line that handles loading 
    # config from git
    class GitConfig
      def self.find_git_dir(work_dir)
        path = File.expand_path(work_dir)
        while path != "/"
          git_dir = File.join(path, ".git")
          return git_dir if File.directory? git_dir
          path = File.dirname(path)
        end
        nil
      end

      def self.find(work_dir=Dir.pwd)
        git_dir = find_git_dir(work_dir)
        new(git_dir) if git_dir
      end

      attr_reader :git_dir

      def initialize(git_dir)
        @git_dir = git_dir
      end

      def find_key(ruby_key)
        re = Regexp.new('^' + ruby_key.gsub('_', '[\._-]') + '$')
        keys = config.keys.grep(re)
        raise LogicError if keys.size > 1
        keys.first
      end

      def get(git_key)
        config[git_key]
      end

      # Funky heuristic
      def app_name_from_remote
        # Infer from origin repo
        repo_url = get('remote.origin.url')
        return nil unless repo_url
        if repo_url.include?('github.com')
          repo_url.match(%r[(?:git@|.*://)[^/:]+[:/](.*).git])[1]
        end
      end

      def commit_id
        git("log -n 1 | head -n 1 | cut -d ' ' -f 2")
      end

      def commit_count
        git("log --oneline | wc -l")
      end

      def branch
        git("branch | grep -e '^* ' | cut -d ' ' -f 2")
      end

      protected

      def config
        @config ||= git("config -l").lines.inject({}) do |conf, line|
          k,v = line.split('=', 2)
          conf[k] = v.rstrip
          conf
        end
      end

      def git(command)
        %x[git --git-dir #{@git_dir} #{command}].strip
      end
    end

    class Config < EnvConfig
      set_keys %w[
        ploy_host
        ploy_api_key

        app_branch
        app_commit_count
        app_commit_id
        app_name
        app_root

        aws_access_key_id
        aws_secret_access_key
        aws_bucket
        aws_private_key_path
      ]
      forward_key :app_basename
      forward_key :app_short_commit_id

      class << self
        def from_git(work_dir=Dir.pwd)
          git = GitConfig.find(work_dir)
          return {} unless git

          config = keys.inject({}) do |c, rb_key|
            git_key = git.find_key(rb_key)
            c[rb_key] = git.get(git_key) if git_key
            c
          end
          config['app_root'] = File.dirname(git.git_dir)
          config['app_name'] ||= git.app_name_from_remote

          config['app_commit_id'] = git.commit_id
          config['app_commit_count'] = git.commit_count
          config['app_branch'] = git.branch
          config
        end

        def load(work_dir=Dir.pwd, env=ENV)
          new(from_git(work_dir).merge from_env(env))
        end
      end

      def app_basename
        File.basename(app_name)
      end

      def app_short_commit_id
        app_commit_id[0..6]
      end
    end

    class << self
      attr_reader :config
    end
    @config = Config.load
    @config.install(CLI)
  end
end
