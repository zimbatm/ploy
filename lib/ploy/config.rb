require 'ploy/errors'

module Ploy
  class Config
    class << self
      def attrs(*attrs)
        @attrs ||= {}

        attrs.flatten.each do |attr_|
          key_rb = attr_.gsub('.', '_')
          @attrs[attr_] = key_rb
          attr_reader(key_rb)
        end

        @attrs
      end

      def git_config
        @git_config ||= %x[git config -l].strip.lines.inject({}) do |conf, line|
          k,v = line.split('=', 2)
          conf[k] = v.rstrip
          conf
        end
      end

      def load
        unless system("git status >/dev/null 2>&1")
          raise ConfigurationError, "git or repo not found"
        end

        config = git_config

        app_root = find_up('.git', Dir.pwd)
        if app_root
          config['app.root'] = app_root
          config['app.name'] ||= find_app_name

          config['app.commit'] = %x[git log -n 1 | head -n 1 | cut -d ' ' -f 2].strip
          config['app.commit_count'] = %x[git log --oneline | wc -l].strip.to_i
          config['app.branch'] = %x[git branch | grep -e '^* ' | cut -d ' ' -f 2].strip
        end

        new(config)
      end

      protected

      def find_up(name, start_path)
        path = File.expand_path(start_path)
        while path != "/"
          return path if File.exists?(File.join(path, name))
          path = File.dirname(path)
        end
        nil
      end

      # Funky heuristic
      def find_app_name
        # Infer from origin repo
        app_repo = %x[git remote -v | grep origin].match(/origin\s*([^\s]+)/)
        app_repo &&= app_repo[1]
        return nil unless app_repo
        if app_repo.include?('github.com')
          app_repo.match(%r[(?:git@|.*://)[^/:]+[:/](.*).git])[1]
        end
      end
    end

    attrs %w[
      ploy.host
      ploy.token

      app.name
      app.root
      app.commit
      app.commit_count
      app.branch

      aws.access_key
      aws.secret_key
      aws.bucket
      aws.private_key_path
    ]

    def initialize(config)
      @config = config

      attrs.each_pair do |key, key_rb|
        value = config[key] || ENV[key_rb.upcase]
        instance_variable_set("@#{key_rb}", value)
      end
    end

    def app_short_commit
      app_commit[0..6]
    end

    def to_s
      attrs.inject([]) do |ary, (key, key_rb)|
        ary + ["#{key}=#{public_send(key_rb).inspect}"]
      end.join("\n")
    end

    protected

    def attrs
      self.class.attrs
    end
  end

  class << self
    attr_reader :config
  end
  @config = Config.load
end
