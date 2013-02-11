module Ploy
  class Environment
    class DSL
      def initialize
        @attributes = {}
        @roles = {}
      end

      def load(filename=nil, &block)
        if block_given?
          instance_eval(&block)
        elsif filename
          instance_eval File.read(filename), filename, 0
        else
          raise ArgumentError, "Expecting a +filename+ or +&block+ as argument"
        end
      end

      def to_hash
        {roles: @roles, attributes: @attributes}
      end

      # These are the methods we want to use in our DSL
      protected

      def set(key, value)
        @attributes[key] = value
      end

      def role(name, &description)
        @roles[name] = description
      end
    end

    # filename or block
    def self.load(filename=nil, &block)
      context = DSL.new
      context.load(filename, &block)
      Environment.new(context.to_hash)
    end

    def initialize(config)
      @attributes = config[:attributes]
      @roles = config[:roles]
    end
  end
end
