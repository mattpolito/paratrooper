module Paratrooper
  class Notifier
    def notify(step_name, options = {})
      self.send(step_name, options)
    end

    def activate_maintenance_mode(options = {}); end
    def deactivate_maintenance_mode(options = {}); end
    def update_repo_tag(options = {}); end
    def push_repo(options = {}); end
    def run_migrations(options = {}); end
    def app_restart(options = {}); end
    def warm_instance(options = {}); end
  end
end
