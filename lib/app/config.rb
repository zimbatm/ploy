require 'fog'
require 'lines'
require 'path'

require 'ploy/env_config'

module App
  class Config < Ploy::EnvConfig
    set_keys %w[
      root_dir
      var_dir

      aws_access_key_id
      aws_secret_access_key
      beanstalk_pool
      database_url
      env
      github_client_id
      github_client_secret
      slug_bucket_name
    ]

    def self.load(root_dir, env=ENV)
      new(from_env(env).merge(
        'root_dir' => root_dir
      ))
    end

    def initialize(config)
      super
      @root_dir = Path(root_dir)
      @var_dir  = @root_dir / 'var'
      
      @env = (ENV['ENV'] || ENV['RACK_ENV'] || 'development').to_sym
      @beanstalk_pool = (@beanstalk_pool || 'localhost:11300').split(',')
      @database_url ||=
        {adapter: 'sqlite3', database: (var_dir / "#{env}.sqlite3").to_s}
    end
  end

  # Install the config on the root object
  class << self
    attr_reader :config

    def log(*a, &b); Lines.log(*a, &b) end
  end
  @config = Config.load File.expand_path('../../..', __FILE__)
  @config.install(App)
end

Lines.context(app: 'ploy', env: App.env)
Lines.use($stderr)

Fog.credentials = {
  aws_access_key_id: App.aws_access_key_id,
  aws_secret_access_key: App.aws_secret_access_key,
#  scheme: 'http',
}

# Disable SSL certificate checking because S3's SSL certificate doesn't work
# on buckets with a "." in them.
Excon.defaults[:ssl_verify_peer] = false

