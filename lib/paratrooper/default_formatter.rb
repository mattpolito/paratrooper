module Paratrooper
  class DefaultFormatter
    def display(message)
      puts
      puts "=" * 80
      puts ">> #{message}"
      puts "=" * 80
      puts
    end
  end
end
