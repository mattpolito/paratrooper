module Paratrooper
  module Callbacks
    def add_callback(name, &block)
      callbacks[name] << block
    end

    def callbacks
      @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    private

    def build_callback(name, context = nil, &block)
      execute_callback("before_#{name}".to_sym, context)
      block.call if block_given?
      execute_callback("after_#{name}".to_sym, context)
    end

    def execute_callback(name, context)
      callbacks[name].each { |c| c.call(context) }
    end
  end
end
