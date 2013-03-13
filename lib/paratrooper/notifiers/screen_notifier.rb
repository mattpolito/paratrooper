require 'paratrooper/notifier'

module Paratrooper

  # Public: Notifier used as default for outputting messages to screen.
  #
  module Notifiers
    class ScreenNotifier < Notifier
      attr_reader :output

      # Public: Initializes ScreenNotifier
      #
      # output - IO object (default: STDOUT)
      def initialize(output = STDOUT)
        @output = output
      end

      # Private: Displays message with decoration
      #
      # message - String message to be displayed
      #
      # Examples
      #
      #   display("Excellent Message")
      #   # =>
      #   # => ==========================================================================
      #   # => >> Excellent Message
      #   # => ==========================================================================
      #   # =>
      def display(message)
        output.puts
        output.puts "=" * 80
        output.puts ">> #{message}"
        output.puts "=" * 80
        output.puts
      end

      def activate_maintenance_mode(options={})
        display("Activating Maintenance Mode")
      end

      def deactivate_maintenance_mode(options={})
        display("Deactivating Maintenance Mode")
      end

      def update_repo_tag(options = {})
        display("Updating Repo Tag: #{options[:tag_name]}")
      end

      def push_repo(options = {})
        display("Pushing #{options[:reference_point]} to Heroku")
      end

      def run_migrations(options = {})
        display("Running database migrations")
      end

      def app_restart(options = {})
        display("Restarting application")
      end

      def warm_instance(options = {})
        display("Accessing #{options[:app_url]} to warm up your application")
      end
    end
  end
end
