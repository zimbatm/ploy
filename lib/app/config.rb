require 'fog'
require 'lines'
require 'path'

module App
  class Config
    def initialize
      @database =
        ENV['DATABASE_URL'] ||
        {adapter: 'sqlite3', database: (App.var_dir / 'dev.sqlite3').to_s}
      @env = (ENV['ENV'] || ENV['RACK_ENV'] || 'development').to_sym
      @beanstalk_pool = ['localhost:11300']
      @slug_bucket_name = ENV['PLOY_SLUG_BUCKET_NAME']
      @aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
      @aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    end

    attr_reader :database
    attr_reader :env
    attr_reader :beanstalk_pool
    attr_reader :slug_bucket_name
    attr_reader :aws_access_key_id
    attr_reader :aws_secret_access_key
  end

  class << self
    attr_reader :config
    attr_reader :root_dir
    attr_reader :var_dir

    def log(*a, &b); Lines.log(*a, &b) end
  end

  @root_dir = Path('../../..').expand(__FILE__)
  @var_dir = @root_dir / 'var'
  @config = Config.new
end

Lines.context(app: 'ploy', env: App.config.env)
Lines.use($stderr)

Fog.credentials = {
  aws_access_key_id: App.config.aws_access_key_id,
  aws_secret_access_key: App.config.aws_secret_access_key,
#  scheme: 'http',
}

# Disable SSL certificate checking because S3's SSL certificate doesn't work
# on buckets with a "." in them.
Excon.defaults[:ssl_verify_peer] = false
