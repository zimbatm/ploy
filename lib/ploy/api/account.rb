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

    # GET /account/keys
    def get_account_keys
      request(
        expects: 200,
        method: :get,
        path: "/account/keys",
      )
    end
  end
end
