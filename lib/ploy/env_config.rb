require 'forwardable'

module Ploy
  # Static environment configuration. Meant as a read-only setup.
  class EnvConfig
    class << self
      attr_reader :keys, :forward_keys
      def set_keys(attributes)
        @keys         = attributes.map(&:to_s)
        @forward_keys = @keys
        attr_reader(*@keys)
      end

      # Attributes that aren't part of the config that also need to be delegated
      # when using the #install method.
      def forward_key(key)
        @forward_keys << key.to_s
        attr_reader key
      end

      def from_env(env)
        keys.inject({}) do |config, key|
          env_key = key.upcase
          config[key] = env[env_key] if env.has_key?(env_key)
          config
        end
      end

      def load(env=ENV)
        new(from_env(env))
      end
    end
    
    def keys; self.class.keys; end
    def forward_keys; self.class.forward_keys; end

    def initialize(config)
      keys.each do |key|
        instance_variable_set("@#{key}", config[key]) if config.has_key?(key)
      end
    end

    def to_s
      forward_keys.inject([]) do |ary, key|
        ary + ["#{key}=#{public_send(key).inspect}"]
      end.join("\n")
    end

    def install(mod)
      mod.extend forward_module
    end

    protected

    def forward_module
      this = self
      @forward_module ||= Module.new do
        this.forward_keys.each do |attr_|
          define_method(attr_) do
            this.public_send(attr_)
          end
        end
      end
    end
  end
end
