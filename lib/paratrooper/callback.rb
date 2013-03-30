module Paratrooper

  # Public: Shell object with methods to be overridden by actual callback objects
  #
  # All callbacks should inherit from this class
  #
  class Callback
    attr_reader :system_caller
    
    def initialize(options = {})
      @system_caller = options[:system_caller] || SystemCaller.new
    end
    
    def run(step_name, options = {})
      self.send("before_#{step_name.to_s}".to_sym, options)
    end

    #
    # To create your own callback override the following methods.
    #

    def before_setup(options = {}); true; end
    def before_activate_maintenance_mode(options = {}); true; end
    def before_deactivate_maintenance_mode(options = {}); true; end
    def before_update_repo_tag(options = {}); true; end
    def before_push_repo(options = {}); true; end
    def before_run_migrations(options = {}); true; end
    def before_app_restart(options = {}); true; end
    def before_warm_instance(options = {}); true; end
    def before_teardown(options = {}); true; end
  end
end
