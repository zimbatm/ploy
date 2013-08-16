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

    # GET /account/tokens
    def get_account_tokens
      request(
        expects: 200,
        method: :get,
        path: "/account/tokens",
      )
    end
  end
end
