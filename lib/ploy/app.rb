module Ploy
  class App
    def self.find_git_dir(path)
      while path != "/"
        return path if File.directory?(File.join(path, ".git"))
        path = File.dirname(path)
      end
      nil
    end

    def self.find(path=Dir.pwd)
      app_root = find_git_dir(path)
      return unless app_root
      app_repo = %x[git remote -v | grep origin].match(/origin\s*([^\s]+)/)[1]
      app_name = app_repo.match(%r[(?:git@|.*://)[^/:]+[:/](.*).git])[1]
      new(app_root, app_name)
    end

    def initialize(root, name)
      @root, @name = root, name
    end

    attr_reader :name
    attr_reader :root
  end
end