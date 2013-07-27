require "bundler/gem_tasks"

def ENV.to_config(keys)
  keys.inject({}) do |hash, key|
    hash[key.downcase] = ENV[key.upcase]
    hash
  end
end

task :default => :spec

task :boot do
  require File.expand_path('../app/boot', __FILE__)
end

namespace :db do
  desc "Updates the database's model"
  task :migrate => :boot do
    require 'active_record'
    ActiveRecord::Migrator.migrations_paths.replace([App.root_dir / 'app/migrations'])
    ActiveRecord::Base.establish_connection(App.config.database)
    ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
  end

  desc "Put some initial data in the DB"
  task :seed => :boot do
    require 'app/models'
    include App::Models

    a = Account.create(email: 'foo@bar.com', password: '1234')
    a.tokens.create

    Token.connection.execute("UPDATE tokens SET id='foobar'")

    provider = a.providers.create(
      name: 'build-service-staging',
      ssh_private_key: `cat ~/.ssh/mcore-jonas.pem`.strip,
      ssh_public_key: `cat ~/.ssh/mcore-jonas.pub`.strip,
      config: {
        provider: 'AWS',
        aws_access_key_id: ENV['AWS_ACCESS_KEY'],
        aws_secret_access_key: ENV['AWS_SECRET_KEY'],
      }
    )

    app = a.apps.create(name: 'zimbatm/build-service')
    app.targets.create(
      provider: provider,
      role: 'server',
      env: 'staging',
      config: {
        run_list: ['recipe[build-service]'],
        build_service: ENV.to_config(%w[AWS_ACCESS_KEY AWS_SECRET_KEY AWS_PRIVATE_KEY GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET])
      }
    )
  end
end

desc "Opens a REPL with the app environment"
task :c => :console
task :console => :boot do
  require 'app/models'
  require 'pry'
  Pry.start(App)
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = FileList['spec/**/*_spec.rb']
end
