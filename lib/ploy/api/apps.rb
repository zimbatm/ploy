module Ploy
  module API
    def get_apps
      request(
        expects: 200,
        method: :get,
        path: "/apps",
      )
    end

    def post_apps(app_name)
      request(
        expects: 201,
        method: :post,
        path: "/apps",
        query: { name: app_name },
      )
    end
  end
end