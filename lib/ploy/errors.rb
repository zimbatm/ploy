module Ploy
  module Error; end
  # Library bugs
  class LogicError < StandardError; include Error; end
  # Library usage error
  class UserError < StandardError; include Error; end
  # Library external errors (memory, network, ...)
  class SystemError < StandardError; include Error; end
end
