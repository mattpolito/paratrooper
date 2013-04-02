require 'active_support/callbacks'

module Paratrooper
  module Callbacks
    extend ::ActiveSupport::Concern
    include ::ActiveSupport::Callbacks
    
    METHODS = [
      "setup", "activate_maintenance_mode", "deactivate_maintenance_mode",
      "update_repo_tag", "push_repo", "run_migrations", "app_restart",
      "warm_instance", "teardown"
    ]
    
    included do
      define_callbacks *METHODS + [{:terminator => 'result === false', :scope => [:kind, :name]}]
      
      METHODS.each do |method|
        define_singleton_method "before_#{method}" do |*args, &block|
          set_callback(method, :before, *args, &block)
        end
        
        define_singleton_method "around_#{method}" do |*args, &block|
          set_callback(method, :around, *args, &block)
        end
        
        define_singleton_method "after_#{method}" do |*args, &block|
          options = args.extract_options!
          options[:prepend] = true
          options[:if] = Array(options[:if]) << "value != false"
          set_callback(method, :after, *(args << options), &block)
        end
      end
    end
    
    def add_callbacks(callbacks)
      callbacks.each do |callback|
        add_callback(callback)
      end
    end
    
    def add_callback(callback)
      METHODS.each do |method|
        add_before_callback(method, callback)
        add_around_callback(method, callback)
        add_after_callback(method, callback)
      end
    end
        
    [:before, :around, :after].each do |kind|
      define_method("add_#{kind}_callback") do |method, callback|
        if callback.respond_to? "#{kind}_#{method}".to_sym
          self.class.set_callback method.to_sym, kind.to_sym, callback
        end
      end
    end
  end
end