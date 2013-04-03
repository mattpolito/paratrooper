require 'paratrooper/callbacks'

module Paratrooper

  # Public: Shell object with callback implementations that call
  # the notifier methods.
  #
  # All notifiers should inherit from this class
  #
  class Notifier
    # Set up before callbacks for all available callback
    # methods which force Notifier classes to behave like
    # existing notifiers.  Notifiers cannot halt the
    # execution by returning false because the callbacks
    # are defined here and always return true.
    Paratrooper::Callbacks::METHODS.each do |method|
      define_method("before_#{method}") do |deployer|
        send(method, deployer.send(:default_payload))
        return true
      end
    end
    
    #
    # To create your own notifier override the following methods.
    #
    
    def setup(options = {}); end
    def activate_maintenance_mode(options = {}); end
    def deactivate_maintenance_mode(options = {}); end
    def update_repo_tag(options = {}); end
    def push_repo(options = {}); end
    def run_migrations(options = {}); end
    def app_restart(options = {}); end
    def warm_instance(options = {}); end
    def teardown(options = {}); end
  end
end
