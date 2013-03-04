module Ploy
  module API
    def get_app(app_name)
      request(
        expects: 200,
        method: :get,
        path: "/app/#{app_name}",
      )
    end

    def get_slugs(app_name)
      request(
        expects: 200,
        method: :get,
        path: "/apps/#{app_name}/slugs",
      )
    end

    def get_targets(app_name)
      request(
        expects: 200,
        method: :get,
        path: "/apps/#{app_name}/targets",
      )
    end
  end
end
