module Paratrooper
  module Callbacks

    # Public: Add misc. function to be called at a later time
    #
    # name  - String name of callback
    #         Example: before_[method_name], after_[method_name]
    # block - Code to be executed during callback
    def add_callback(name, &block)
      callbacks[name] << block
    end

    def callbacks
      @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def build_callback(name, context = nil, &block)
      execute_callback("before_#{name}".to_sym, context)
      block.call if block_given?
      execute_callback("after_#{name}".to_sym, context)
    end

    private

    def execute_callback(name, context)
      callbacks[name].each { |c| c.call(context) }
    end
  end
end
