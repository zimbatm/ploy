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
    
    def get_app(app_name)
      request(
        expects: 200,
        method: :get,
        path: "/apps/#{app_name}",
      )
    end

    def get_app_slugs(app_name)
      request(
        expects: 200,
        method: :get,
        path: "/apps/#{app_name}/slugs",
      )
    end

    def get_app_targets(app_name)
      request(
        expects: 200,
        method: :get,
        path: "/apps/#{app_name}/targets",
      )
    end

    def post_app_deploy(app_name, commit_id, env)
      request(
        expects: 200,
        method: :post,
        path: "/apps/#{app_name}/deploy",
        query: {commit_id: commit_id, env: env}
      )
    end
  end
end
