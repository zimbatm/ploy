require 'base64'
require 'excon'
require 'multi_json'

require 'ploy/api/account'
require 'ploy/api/apps'
require 'ploy/api/providers'

require 'ploy/errors'
require 'ploy/version'

module Ploy
  # Copyright MIT Heroku: https://github.com/heroku/heroku.rb/blob/master/lib/heroku/api.rb
  class Client
    include API

    HEADERS = {
      'Accept'                => 'application/json',
      'User-Agent'            => "ploy/#{Ploy::VERSION}",
      'X-Ruby-Version'        => RUBY_VERSION,
      'X-Ruby-Platform'       => RUBY_PLATFORM,
    }

    OPTIONS = {
      :headers  => {},
      :host     => 'localhost',
      :nonblock => false,
      :scheme   => 'http'
    }

    def initialize(options={})
      options = OPTIONS.merge(options)

      @scheme = options.delete(:scheme)
      @host = options.delete(:host) || ENV['PLOY_HOST']
      @auth = options.delete(:auth) || ENV['PLOY_AUTH']

      options[:headers] = HEADERS.merge({
        'Authorization' => "Basic #{Base64.encode64(@auth).gsub("\n", '')}",
      }).merge(options[:headers])

      @connection = Excon.new("#{@scheme}://#{@host}", options)
    end

    def request(params, &block)
      begin
        response = @connection.request(params, &block)
      rescue Excon::Errors::HTTPStatusError => error
        klass = case error.response.status
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

      response
    end
  end
end
