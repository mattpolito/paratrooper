require 'paratrooper/error'

module Paratrooper
  class SystemCaller
    class ErrorSystemExit < Paratrooper::Error
      def initialize(cmd)
        msg = "The system command '#{cmd}' has exited unsuccessfully"
        super(msg)
      end
    end
    attr_accessor :debug

    def initialize(debug = false)
      @debug = debug
    end

    def execute(cmd, exit_code = false)
      debug_message_for(cmd)
      result = %x[#{cmd}]
      if exit_code && $? != 0
        fail(ErrorSystemExit.new(cmd))
      end
      result
    end

    private

    def debug_message_for(cmd)
      puts "DEBUG: #{cmd}" if debug
    end
  end
end
