module Paratrooper
  class SystemCaller
    def execute(call)
      system(call)
    end
    
    def run(call)
      `#{call}`
    end
  end
end
