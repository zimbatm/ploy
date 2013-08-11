require 'grape_entity'

module App
  module Entities
    class Account < Grape::Entity
      root 'accounts', 'account'
      expose :id
      expose :email
      expose :full_name

      expose :created_at
      expose :updated_at
    end

    class Application < Grape::Entity
      root 'applications', 'application'
      expose :id
      expose :name

      expose :created_at
      expose :updated_at
    end

    class Token < Grape::Entity
      expose :id
      expose :active

      expose :created_at
      expose :updated_at
    end

    class Slug < Grape::Entity
      expose :id

      expose :commit_id
      expose :branch

      expose :created_at
      expose :updated_at
    end

    class Provider < Grape::Entity
      expose :id
      expose :name

      expose :config

      expose :created_at
      expose :updated_at
    end

    class Target < Grape::Entity
      expose :id

      expose :role
      expose :env
      expose :config

      expose :application_id
      expose :provider_id
      expose :slug_id

      expose :deployed_at

      expose :created_at
      expose :updated_at
    end

    class BuildJob < Grape::Entity
      expose :id

      expose :app_name
      expose :build_id
      expose :commit_id
      expose :branch

      expose :state
    end


  end
end
