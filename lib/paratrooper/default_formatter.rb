module Paratrooper

  # Public: Formatter used as default for outputting messages to command line
  #
  class DefaultFormatter
    attr_reader :output

    # Public: Initializes DefaultFormatter
    #
    # output - IO object (default: STDOUT)
    def initialize(output = STDOUT)
      @output = output
    end

    # Public: Displays message with decoration
    #
    # message - String message to be displayed
    #
    # Examples
    #
    #   display("Excellent Message")
    #   # =>
    #   # => ==========================================================================
    #   # => >> Excellent Message
    #   # => ==========================================================================
    #   # =>
    def display(message)
      output.puts
      output.puts "=" * 80
      output.puts ">> #{message}"
      output.puts "=" * 80
      output.puts
    end
  end
end
