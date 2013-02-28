module Ploy
  module API
    def get_apps
      request(
        expects: 200,
        method: :get,
        path: "/apps",
      )
    end
  end
end