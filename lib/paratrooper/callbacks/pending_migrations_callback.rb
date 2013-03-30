require 'paratrooper/callback'

module Paratrooper
  module Callbacks

    # Public: Optional callback to skip deploy steps unless there are pending
    # migrations
    #
    class PendingMigrationsCallback < Callback
      attr_reader :git_diff
      
      def before_activate_maintenance_mode(options = {})
        return pending_migrations?(options[:tag_name])
      end
      
      def before_deactivate_maintenance_mode(options = {})
        return pending_migrations?(options[:tag_name])
      end
      
      def before_run_migrations(options = {})
        return pending_migrations?(options[:tag_name])
      end
      
      def before_app_restart(options = {})
        return pending_migrations?(options[:tag_name])
      end
      
    private
    
      def pending_migrations?(tag_name)
        @git_diff ||= system_caller.run("git diff --shortstat #{tag_name} master db/migrate")
        !(git_diff.strip.empty?)
      end
    end
  end
end
