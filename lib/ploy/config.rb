require 'ploy/errors'

module Ploy
  class Config
    def self.load
      unless system("git status >/dev/null")
        raise ConfigurationError, "git or repo not found"
      end

      host = %x[git config ploy.host].strip
      token = %x[git config ploy.token].strip

      new(host: (host unless host.empty?), token: (token unless token.empty?))
    end

    attr_accessor :host, :token

    def initialize(config)
      @host = config[:host]
      @token = config[:token]
    end
  end

  @config = Config.load
  class << self
    attr_reader :config
  end
end
