require 'stringio'

module Paratrooper
  class DefaultFormatter
    attr_reader :output

    def initialize(output = STDOUT)
      @output = output
    end

    def display(message)
      output.puts
      output.puts "=" * 80
      output.puts ">> #{message}"
      output.puts "=" * 80
      output.puts
    end
  end
end
