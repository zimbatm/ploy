module Ploy
  module API
    def post_new_build(app_name, commit_id, branch)
      request(
        expects: 201,
        method: :post,
        path: "/apps/#{app_name}/build",
        query: { commit_id: commit_id, branch: branch }
      )
    end

    def get_build_list(app_name)
      request(
        expect: 200,
        method: :get,
        path: "/apps/#{app_name}/build",
      )
    end
  end
end
