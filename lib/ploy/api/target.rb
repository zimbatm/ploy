module Ploy
  module API
    def get_targets
      request(
        expects: 200,
        method: :get,
        path: "/targets",
      )
    end
  end
end