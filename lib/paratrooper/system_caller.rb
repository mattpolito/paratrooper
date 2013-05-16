module Paratrooper
  class SystemCaller
    attr_accessor :debug

    def initialize(debug = false)
      self.debug = debug
    end

    def execute(call)
      debug_message_for(call)
      system(call)
    end

    private
    def debug_message_for(call)
      p "DEBUG: #{call}" if debug
    end
  end
end
