module Ploy
  module API
    # GET /services
    def get_services
      request(
        expects: 200,
        method: :get,
        path: "/services",
      ).body
    end
  end
end