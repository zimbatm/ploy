module Ploy
  module API
    # GET /providers
    def get_providers
      request(
        expects: 200,
        method: :get,
        path: "/providers",
      )
    end
  end
end
