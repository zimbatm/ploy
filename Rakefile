require "bundler/gem_tasks"

def ENV.to_config(keys)
  keys.inject({}) do |hash, key|
    hash[key.downcase] = ENV[key.upcase]
    hash
  end
end

task :default => :spec

task :boot do
  require File.expand_path('../boot', __FILE__)
end

directory 'var'

desc "Creates base architecture for testing"
task :init => ['db:migrate'] do
  require 'app/models'
  include App::Models

  a = Account.create(email: 'foo@bar.com')
  a.api_keys.create

  ApiKey.connection.execute("UPDATE api_keys SET id='foobar'")

  provider = a.providers.create(
    name: 'build-service-staging',
    ssh_private_key: 'totoooyoy',
    ssh_public_key: 'yooooo',
    config: {
      provider: 'AWS',
      aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    }
  )

  app = a.apps.create(name: 'zimbatm/ploy-example')
  app.targets.create(
    provider: provider,
    role: 'server',
    env: 'staging',
    config: JSON.dump(
      run_list: ['recipe[ploy-example]']
    )
  )
  app.data_dir.mkdir_p
  system("git clone --mirror #{app.repo_url} #{app.data_dir}/source_repo")
end

namespace :db do
  desc "Updates the database's model"
  task :migrate => [:var, :boot] do
    require 'app/models'
    require 'active_record'
    ActiveRecord::Migrator.migrations_paths.replace([App.root_dir / 'lib/app/migrations'])
    ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
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
