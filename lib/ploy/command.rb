module Ploy
  class Command
    def self.run(args)
      new(args).run
    end

    def initialize(args)
      @args = args
    end

    def run
    end
  end
end
