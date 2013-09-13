module Paratrooper
  module Callbacks
    def callback(name, &block)
      execute_callback("before_#{name}".to_sym)
      block.call if block_given?
      execute_callback("after_#{name}".to_sym)
    end

    def execute_callback(name)
      callbacks[name].each(&:call)
    end

    def add_callback(name, &block)
      callbacks[name] << block
    end

    def callbacks
      @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end
  end
end
