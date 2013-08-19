require 'active_record'
require 'bcrypt'
require 'fog'
require 'lines/active_record'
require 'paranoia'
require 'uri'

require 'app/config'
require 'app/generated_id'
require 'app/hash_serializer'

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

      has_many :api_keys

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

    class ApiKey < Base
      include Common

      belongs_to :account
    end

    class Application < Base
      include Common

      validates_format_of   :name, with: /\A[\w\-\.]+\/[\w\-\.]+\z/

      has_many :slugs
      has_many :targets
      has_many :builds

      def basename; File.basename(name); end

      def data_dir
        App.var_dir / 'apps' / name
      end
    end

    class Slug < Base
      include Common

      belongs_to :application
      validates_presence_of :build_id
      validates_presence_of :commit_id
      validates_presence_of :branch
      validates_presence_of :url

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

      def short_commit_id
        commit_id[0..6]
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

    class Build < Base
      self.primary_key = :id
      before_create :set_key
      before_create :init_state

      default_scope { order("created_at DESC") }

      validates_presence_of :application
      validates_presence_of :commit_id
      validates_presence_of :branch
      
      belongs_to :application

      VALID_STATES = %[pending building uploading success error]

      def change_state(new_state)
        new_state = new_state.to_s
        fail "cannot transition from success" if state == "success"
        fail "not a valid state" unless VALID_STATES.include?(new_state)
        update_attribute(:state, new_state)
      end

      def build_dir
        application.data_dir / 'builds' / id
      end

      def cache_dir
        application.data_dir / 'cache'
      end

      def source_dir
        application.data_dir / 'source_repo'
      end

      protected

      def set_key
        id = "#{Time.now.to_i.to_s}-#{application.basename}-#{branch}-#{commit_id[0..6]}"
        write_attribute(:id, id)
      end

      def init_state
        write_attribute(:state, "pending")
      end
    end
  end

  include Models
end

ActiveRecord::Base.establish_connection(App.config.database_url)
