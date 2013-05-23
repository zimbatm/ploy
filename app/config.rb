require 'fog'
require 'lines'
require 'path'

module App
  class Config
    def initialize
      @database =
        ENV['DATABASE_URL'] ||
        {adapter: 'sqlite3', database: (App.root_dir / 'dev.sqlite3').to_s}
      @env = (ENV['ENV'] || ENV['RACK_ENV'] || 'development').to_sym
    end

    attr_reader :database
    attr_reader :env
  end

  class << self
    attr_reader :config
    attr_reader :root_dir

    def log(*a, &b); Lines.log(*a, &b) end
  end

  @root_dir = Path('../..').expand(__FILE__)
  @config = Config.new
end

Lines.context(app: 'ploy', env: App.config.env)
Lines.use($stderr)

Fog.credentials = {
  aws_access_key_id: ENV['AWS_ACCESS_KEY'],
  aws_secret_access_key: ENV['AWS_SECRET_KEY'],
#  scheme: 'http',
}

# Disable SSL certificate checking because S3's SSL certificate doesn't work
# on buckets with a "." in them.
Excon.defaults[:ssl_verify_peer] = false

