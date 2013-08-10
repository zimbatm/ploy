require 'active_record'
require 'bcrypt'
require 'fog'
require 'generated_id'
require 'hash_serializer'
require 'lines/active_record'
require 'paranoia'
require 'uri'

module App
  module Models
    Base = ActiveRecord::Base

    module Common
      def self.included(klass)
        klass.send(:include, GeneratedID)
        klass.acts_as_paranoid
      end
    end

    class Account < Base
      include Common
      include BCrypt
      default_scope ->{ order(:created_at) }

      has_many :tokens

      validates_presence_of :email
      validates_format_of   :email, with: /.+@.+/

      validates_presence_of :hashed_password

      def password
        @password ||= Password.new(hashed_password)
      end

      def password=(new_password)
        @password = Password.create(new_password)
        self.hashed_password = @password
      end

      # For now all apps are shared with everyone
      def apps
        Application.all
      end

      # For now all providers are shared with everyone
      def providers
        Provider.all
      end

    end

    class Token < Base
      include Common

      belongs_to :account
    end

    class Application < Base
      include Common

      has_many :slugs
      has_many :targets

      def basename; File.basename(name); end

      def build(commit_id, branch)
        slug = slugs.create!(build_id: Time.now.to_i.to_s, commit_id: commit_id, branch: branch)

        BuildWorker.perform_async(slug.id)
      end
    end

    class Slug < Base
      include Common

      VALID_STATES = %w[pending building complete]

      belongs_to :application
      validates_presence_of :build_id
      validates_presence_of :commit_id
      validates_presence_of :branch
      validates_presence_of :url

      before_create :init_state

      alias app application

      def public_url
        uri = URI.parse(url)
        return url if %[http https].include?(uri.scheme)
        provider = service_to_provider(uri.scheme)
        Fog::Storage[provider].get_object_http_url(uri.host, uri.path[1..-1], 1.day.from_now)
      end

      def service_to_provider(scheme)
        case scheme
        when 's3'
          :AWS
        else
          fail "Unknown service: #{scheme}"
        end
      end

      def build_id
        [app.basename,
          Time.now.to_i,
          branch,
          # commit_count ?
          short_commit].join('-')
      end

      def short_commit
        commit_id[0..6]
      end

      protected

      def init_state
        self.state = 'pending'
      end
    end

    class Provider < Base
      include Common

      serialize :config, HashSerializer.new

      validates_presence_of :name
      validates_presence_of :ssh_private_key
      validates_presence_of :ssh_public_key

      #validates(:config) { compute }

      def servers; compute.servers; end

      def servers_for_target(target)
        sg = target.name
        servers.select do |server|
          server.private_key = ssh_private_key
          server.groups.include?(sg) && server.state == "running"
        end
      end

      def get_server(server_id)
        s = servers.get(server_id)
        s.private_key = ssh_private_key
        s
      end

      protected

      def compute
        Fog::Compute.new(
          self.config.symbolize_keys
        )
      end
    end

    class Target < Base
      include Common

      belongs_to :application
      belongs_to :slug
      belongs_to :provider

      serialize :config, HashSerializer.new

      def hosts
        provider.servers_for_target(self)
      end

      def get_host(host_id)
        provider.get_server(host_id)
      end

      def name
        [application.name, env, role].join(',')
      end

      # TODO: Create host, remove host
      # TODO: When creating, create the associated security group
      # TODO: When destroying, destroy the associated servers
      # TODO: SecurityGroup port mapping
    end

    # Here we use incremental IDs
    class Deploy < Base
      belongs_to :target
      belongs_to :slug
    end
  end

  include Models
end

ActiveRecord::Base.establish_connection(App.config.database)
