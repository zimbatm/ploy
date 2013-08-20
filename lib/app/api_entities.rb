require 'grape_entity'

module App
  module Entities
    class Entity < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt.iso8601 }
    end

    class Account < Entity
      root 'accounts', 'account'
      expose :id
      expose :email
      expose :full_name

      with_options(format_with: :iso_timestamp ) do
        expose :created_at
        expose :updated_at
      end
    end

    class ApiKey < Entity
      root 'api_keys', 'api_key'
      expose :id
      expose :active

      with_options(format_with: :iso_timestamp ) do
        expose :created_at
        expose :updated_at
      end
    end

    class Application < Entity
      root 'applications', 'application'
      expose :id
      expose :name

      with_options(format_with: :iso_timestamp ) do
        expose :created_at
        expose :updated_at
      end
    end

    class Provider < Entity
      root 'providers', 'provider'
      expose :id
      expose :name

      expose :config

      with_options(format_with: :iso_timestamp ) do
        expose :created_at
        expose :updated_at
      end
    end

    class Slug < Entity
      root 'slugs', 'slug'
      expose :id

      expose :commit_id
      expose :branch

      expose :checksum
      expose :url

      with_options(format_with: :iso_timestamp ) do
        expose :created_at
        expose :updated_at
      end
    end

    class Target < Entity
      root 'targets', 'target'
      expose :id

      expose :role
      expose :env
      expose :config

      expose :application,  using: Application
      expose :provider,     using: Provider
      expose :slug,         using: Slug

      with_options(format_with: :iso_timestamp ) do
        expose :deployed_at
        expose :created_at
        expose :updated_at
      end
    end

    class Build < Entity
      root 'builds', 'build'
      expose :id

      expose :app_name
      expose :build_id
      expose :commit_id
      expose :branch

      expose :state
    end
  end
end
