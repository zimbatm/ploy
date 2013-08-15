require 'base64'
require 'grape'

require 'app/api_entities'
require 'app/models'
require 'app/workers'

module App
  class API < Grape::API
    include Models

    version 'v1', using: :header, vendor: 'ploy'
    format :json

    # Presenters setup
    represent Account, with: Entities::Account
    represent Application, with: Entities::Application
    represent Provider, with: Entities::Provider
    represent Slug, with: Entities::Slug
    represent Target, with: Entities::Target
    represent Token, with: Entities::Token

    rescue_from ActiveRecord::RecordNotUnique do |e|
      Rack::Response.new('Already exists', 400)
    end

    helpers do
      def basic_pair
        env['HTTP_AUTHORIZATION'].to_s =~ /Basic ([^\s]+)/
        return [] unless $1
        Base64.decode64($1).split(':', 2)
      end

      def account
        return @account if @account

        token_id = params['token'] || basic_pair.first

        token = token_id && Token.where(id: token_id, active: true).first
        @account = token.account if token

        @account || error!('Unauthorized', 401)
      end

      def not_found!
        error!('Not found', 404)
      end
    end

    desc "Hi"
    get do
      {Hi: true, token: Token.first.id}
    end

    desc "Exposes the user's account informations", {
      object_fields: Entities::Account.documentation
    }
    get '/account' do
      present account
    end

    namespace '/tokens' do
      desc "Returns the account's tokens", {
        object_fields: Entities::Token.documentation
      }
      get do
        present account.tokens
      end
    end

    namespace '/providers' do
      desc "Returns the available services", {
        object_fields: Entities::Provider.documentation
      }
      get do
        present account.providers
      end
    end

    namespace '/apps' do
      desc "Returns all the apps"
      get do
        present account.apps
      end

      desc "Creates a new app"
      params do
        # FIXME: match github_user/github_repo
        requires :name, type: String, desc: "Application name"
      end
      post do
        present account.apps.create!(declared(params))
      end

      params do
        requires :github_user, type: String, desc: "GitHub account"
        requires :github_repo, type: String, desc: "GitHub repo name"
      end
      namespace '/:github_user/:github_repo/' do
        helpers do
          def app
            @app ||= (
              app_name = [params[:github_user], params[:github_repo]].join('/')
              account.apps.find_by_name app_name
            ) || not_found!
          end
        end

        get do
          present app
        end

        namespace '/build' do
          desc "Creates a new slug"
          params do
            requires :commit_id, type: String, desc: "Id of the commit to build"
            requires :branch, type: String, desc: "Branch to build"
          end
          post do
            build = app.builds.create!(commit_id: params[:commit_id], branch: params[:branch])
            BuildWorker.perform_async(build)
            present build
          end

          get do
            present app.builds
          end

          params do
            requires :build_id, type: String, desc: "build_id"
            optional :tail, type: Boolean, desc: "Follows changes in the file"
          end
          get '/logs' do
            build = app.builds.find(params[:build_id])
            p [:build, build]
            halt 404 unless build
            case build.state
            when "pending"
              halt 404
            #when "success"
              # TODO: get from S3
            else
              # TODO: support tail=true
              body = File.open(build.build_dir / 'build.log')
              [200, {'Content-Type' => 'text/plain'}, body]
            end
          end
        end

        namespace '/slugs' do
          desc 'Returns all the slugs for the app'
          get do
            present app.slugs
          end

          desc 'Registers a new slug'
          params do
            requires :build_id, type: String, desc: "Jenkins build ID"
            requires :commit_id, type: String, desc: "ID of the commit where the slug was built"
            requires :branch, type: String, desc: "Branch of the commit"

            requires :url, type: String, desc: "Where to fetch the build"
          end
          post do
            present app.slugs.create!(declared(params))
          end

          get ':slug_id' do
            present app.slugs.find(params[:slug_id])
          end

          delete ':slug_id' do
            present app.slugs.delete(params[:slug_id])
          end
        end

        namespace '/targets' do
          desc 'Returns all the deploy targets for the app'
          get do
            present app.targets
          end

          desc 'Creates a new deploy target for the app'
          post do
            present app.targets.create!(declared(params))
          end
        end

        desc 'Deploy new code'
        params do
          optional :slug, type: String, desc: "Find the slug by it's ID"
          optional :commit_id, type: String, desc: "Find the slug by a commit_id"

          optional :role, type: String, desc: "Filter the target by role"
          optional :env, type: String, desc: "Filter the target by env"
        end
        post '/deploy' do
          content_type :text

          if params[:slug]
            slug = app.slugs.find(params[:slug])
          elsif params[:commit_id]
            slug = app.slugs.find_by_commit_id(params[:commit_id])
          else
            slug = app.slugs.find_by_branch("master")
          end

          raise ArgumentError, "slug missing" unless slug

          targets = app.targets
          targets = targets.where("role = ?", params[:role]) if params[:role]
          targets = targets.where("env = ?", params[:env]) if params[:env]

          Lines.log(msg: "Deploying on", commit_id: slug.commit_id, targets: targets.map{|t| t.name})

          ret = targets.map do |target|
            deploy = Deploy.create!(target: target, slug: slug)
            target.hosts.map do |host|
              HostDeployWorker.perform_async(deploy.id, host.id)
            end
          end.flatten
          present ret
        end
      end
    end

  end
end
