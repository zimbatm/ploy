module Ploy
  module Errors
    module Error; end

    class ErrorWithResponse < StandardError
      include Error
      attr_reader :response

      def initialize(message, response)
        super message
        @response = response
      end
    end

    class Unauthorized < ErrorWithResponse; end
    class VerificationRequired < ErrorWithResponse; end
    class Forbidden < ErrorWithResponse; end
    class NotFound < ErrorWithResponse; end
    class Timeout < ErrorWithResponse; end
    class Locked < ErrorWithResponse; end
    class RequestFailed < ErrorWithResponse; end
    
    class ServiceNotAvailable < StandardError; include Error; end


    class ConfigurationError < StandardError; include Error; end
  end
  include Errors
end
