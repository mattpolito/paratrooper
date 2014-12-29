module Paratrooper
  class SystemCaller
    attr_accessor :debug

    def initialize(debug = false)
      @debug = debug
    end

    def execute(call)
      debug_message_for(call)
      `#{call}`
    end

    private

    def debug_message_for(cmd)
      puts "DEBUG: #{cmd}" if debug
    end
  end
end
