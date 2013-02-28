module Ploy
  module API
    # GET /account
    def get_account
      request(
        expects: 200,
        method: :get,
        path: "/account",
      )
    end

    # GET /tokens
    def get_tokens
      request(
        expects: 200,
        method: :get,
        path: "/tokens",
      )
    end
  end
end