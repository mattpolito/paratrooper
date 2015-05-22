module Paratrooper

  # Public: Shell object with methods to be overridden by other notifiers
  #
  # All notifiers should inherit from this class
  #
  class Notifier
    def notify(step_name, options = {})
      self.send(step_name, options)
    end

    #
    # To create your own notifier override the following methods.
    #

    def setup(options = {}); end
    def activate_maintenance_mode(options = {}); end
    def deactivate_maintenance_mode(options = {}); end
    def update_repo_tag(options = {}); end
    def push_repo(options = {}); end
    def push_slug(options = {}); end
    def run_migrations(options = {}); end
    def app_restart(options = {}); end
    def warm_instance(options = {}); end
    def teardown(options = {}); end
  end
end
