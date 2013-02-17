module Paratrooper
  class SystemCaller

    attr_accessor :status

    def execute(call)
      status = system(call)
    end
  end
end
