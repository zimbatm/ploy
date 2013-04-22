require 'base64'
require 'excon'
require 'multi_json'

require 'ploy/api/account'
require 'ploy/api/app'
require 'ploy/api/provider'
require 'ploy/api/target'

require 'ploy/errors'
require 'ploy/version'

module Ploy
  # Copyright MIT Heroku: https://github.com/heroku/heroku.rb/blob/master/lib/heroku/api.rb
  class Client
    include API

    # Turns the response around so that response.body is the object
    # but you can still get access to the original response by calling +#response+
    # on the object.
    module EmbedResponse
      attr_reader :response

      def self.wrap(object, response)
        object.extend EmbedResponse
        object.instance_variable_set('@response', response)
        object
      end
    end

    HEADERS = {
      'Accept'                => 'application/json',
      'User-Agent'            => "ploy/#{Ploy::VERSION}",
      'X-Ruby-Version'        => RUBY_VERSION,
      'X-Ruby-Platform'       => RUBY_PLATFORM,
    }

    OPTIONS = {
      headers:  {},
      host:     'localhost',
      nonblock: false,
      scheme:   'http',
    }

    def initialize(options={})
      options = OPTIONS.merge(options)

      @scheme = options.delete(:scheme)
      @host = options.delete(:host) || ENV['PLOY_HOST']
      @token = options.delete(:token) || ENV['PLOY_TOKEN']

      options[:headers] = HEADERS.merge({
        'Authorization' => "Basic #{Base64.encode64(@token + ':').rstrip}",
      }).merge(options[:headers])

      @connection = Excon.new("#{@scheme}://#{@host}", options)
    end

    def get(path, query={})
      simple_request(:get, path, query)
    end

    def post(path, query={})
      simple_request(:get, path, query)
    end

    def put(path, query={})
      simple_request(:get, path, query)
    end

    def delete(path, query={})
      simple_request(:get, path, query)
    end

    def simple_request(method, path, query={})
      params = {method: method, path: path}
      params[:query] = query if query && query.size > 0
      request(params)
    end

    def request(params, &block)
      begin
        response = @connection.request(params, &block)
      rescue Excon::Errors::HTTPStatusError => error
        klass = case error.response[:status]
          when 401 then Ploy::Errors::Unauthorized
          when 402 then Ploy::Errors::VerificationRequired
          when 403 then Ploy::Errors::Forbidden
          when 404 then Ploy::Errors::NotFound
          when 408 then Ploy::Errors::Timeout
          when 422 then Ploy::Errors::RequestFailed
          when 423 then Ploy::Errors::Locked
          when /50./ then Ploy::Errors::RequestFailed
          else Ploy::Errors::ErrorWithResponse
        end

        reerror = klass.new(error.message, error.response)
        reerror.set_backtrace(error.backtrace)
        raise(reerror)
      rescue Excon::Errors::SocketError => error
        reerror = Ploy::Errors::ServiceNotAvailable.new(error.message)
        reerror.set_backtrace(error.backtrace)
        raise(reerror)
      end

      if response.body && !response.body.empty?
        if response.headers['Content-Encoding'] == 'gzip'
          response.body = Zlib::GzipReader.new(StringIO.new(response.body)).read
        end

        if response.headers['Content-Type'].to_s =~ /json/
          response.body = MultiJson.decode(response.body)
        end
      end

      # reset (non-persistent) connection
      @connection.reset

      EmbedResponse.wrap(response.body, response)
    end
  end
end
