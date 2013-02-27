module Ploy
  module API
    # GET /account
    def get_account
      request(
        expects: 200,
        method: :get,
        path: "/account",
      ).body
    end

    # GET /tokens
    def get_tokens
      request(
        expects: 200,
        method: :get,
        path: "/tokens",
      ).body
    end
  end
end