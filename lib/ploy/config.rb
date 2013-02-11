require 'ploy/errors'

module Ploy
  class Config
    def self.load
      unless system("git status >/dev/null")
        raise ConfigurationError, "git or repo not found"
      end

      host = %x[git config ploy.host]
      user = %x[git config ploy.user]
      token = %x[git config ploy.token]

      new(host: host, user: user, token: token)
    end

    attr_accessor :host, :user, :token

    def initialize(config)
      @host = config[:host]
      @user = config[:user]
      @token = config[:token]
    end
  end

  @config = Config.load
  class << self
    attr_reader :config
  end
end
