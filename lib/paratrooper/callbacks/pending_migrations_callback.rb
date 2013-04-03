module Paratrooper
  module Callbacks

    # Public: Optional callback to skip deploy steps unless there are pending
    # migrations
    #
    class PendingMigrationsCallback
      attr_reader :git_diff
      
      def before_activate_maintenance_mode(options = {})
        return pending_migrations?(options[:tag_name], options[:match_tag])
      end
      
      def before_deactivate_maintenance_mode(options = {})
        return pending_migrations?(options[:tag_name], options[:match_tag])
      end
      
      def before_run_migrations(options = {})
        return pending_migrations?(options[:tag_name], options[:match_tag])
      end
      
      def before_app_restart(options = {})
        return pending_migrations?(options[:tag_name], options[:match_tag])
      end
      
    private
    
      def pending_migrations?(tag_name, match_to)
        @git_diff ||= system_caller.run("git diff --shortstat #{tag_name} #{match_to} db/migrate")
        !(git_diff.strip.empty?)
      end
    end
  end
end