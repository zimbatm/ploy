require 'ploy/errors'

module Ploy
  class Config
    module GitLoader
      def attrs(new_attributes = [])
        @attrs ||= []

        new_attributes.each do |attr_|
          @attrs << attr_.to_sym
          attr_reader(attr_)
        end

        @attrs
      end

      def load
        unless system("git status >/dev/null 2>&1")
          raise ConfigurationError, "git or repo not found"
        end

        config = {
          host: %x[git config ploy.host].strip,
          token: %x[git config ploy.token].strip,
          app_root: find_up('.git', Dir.pwd),
        }

        if config[:app_root]
          config[:commit_id] = %x[git log -n 1 | head -n 1 | cut -d ' ' -f 2].strip
          config[:branch] = %x[git branch | grep -e '^* ' | cut -d ' ' -f 2].strip
          config[:app_name] = find_app_name
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
        app_name = %x[git config ploy.app_name 2>/dev/null].strip
        return app_name unless app_name.empty?

        # Infer from origin repo
        app_repo = %x[git remote -v | grep origin].match(/origin\s*([^\s]+)/)[1]
        if app_repo.include?('github.com')
          app_repo.match(%r[(?:git@|.*://)[^/:]+[:/](.*).git])[1]
        end
      end
    end

    extend GitLoader

    attrs %w[
      host
      token

      commit_id
      branch

      app_name
      app_root
    ]

    def initialize(config)
      keys = config.keys - self.class.attrs
      raise "Unknown keys: #{keys.inspect}" unless keys.empty?
      attrs.each do |key|
        value = config[key]
        instance_variable_set("@#{key}", value) unless value.to_s.empty?
      end
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
