module Ploy
  class Client < Faraday::Client
    def initialize(host, auth)
      super(url: 'http://#{host}') do |faraday|
        faraday.request = :url_encoded
        faraday.response = :logger
        faraday.adapter  Faraday.default_adapter
      end
    end
  end
end