module Ploy
  module Errors
    class PloyError < StandardError; end

    class ConfigurationError < PloyError; end
  end
  include Errors
end
