require 'forwardable'

module Paratrooper
  module Callbacks
    extend Forwardable

    def_delegators :@callbacks, :[], :clear

    HOOKS = %w(activate_maintenance_mode update_repo_tag push_repo run_migrations app_restart deactivate_maintenance_mode warm_instance)

    # Generate alias methods to
    # all deploy methods
    #
    HOOKS.each do |method|
      class_eval <<-EOF, __FILE__, __LINE__
        def #{method}_with_callbacks(*args)
          execute_callbacks_for(:#{method}, :before)
          #{method}_without_callbacks(*args)
          execute_callbacks_for(:#{method}, :after)
        end
      EOF
    end

    def self.included(base)
      HOOKS.each do |method|
        base.class_eval do
          alias_method "#{method}_without_callbacks", method
          alias_method method, "#{method}_with_callbacks"
        end
      end
    end

    # Public: Execute callbacks
    #
    # method - Symbol of method that contains callbacks
    # position - Symbol specifing if :before or :after callbacks
    def execute_callbacks_for(method, position)
      return unless callbacks[position][method]

      while callback = callbacks[position][method].shift
        `#{callback}`
      end
    end

    def callbacks
      @callbacks ||= Hash.new { |h, k| h[k] = {} }
    end

    # Public: Append callbacks after method
    #
    # command - Symbol specified a default deploy method
    # hook - String with command to be executed
    def after(command, hook)
      callbacks[:after][command] ||= []
      callbacks[:after][command] << hook
    end

    # Public: Append callbacks before method
    #
    # command - Symbol specified a default deploy method
    # hook - String with command to be executed
    def before(command, hook)
      callbacks[:before][command] ||= []
      callbacks[:before][command] << hook
    end
  end
end
