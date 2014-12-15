require 'paratrooper/notifier'

module Paratrooper
  module Notifiers

    # Public: Default notifier for outputting messages to screen.
    #
    class ScreenNotifier < Notifier
      attr_reader :output

      # Public: Initializes ScreenNotifier
      #
      # output - IO object (default: STDOUT)
      def initialize(output = STDOUT)
        @output = output
      end

      # Public: Displays message with decoration
      #
      # message - String message to be displayed
      #
      # Examples
      #
      #   display("Excellent Message")
      #   # =>
      #   # => =============================================================
      #   # => >> Excellent Message
      #   # => =============================================================
      #   # =>
      def display(message)
        output.puts
        output.puts "=" * 60
        output.puts ">> #{message}"
        output.puts "=" * 60
        output.puts
      end

      def activate_maintenance_mode(options = {})
        display("Activating Maintenance Mode - Enabled due to pending migrations")
      end

      def deactivate_maintenance_mode(options = {})
        display("Deactivating Maintenance Mode")
      end

      def update_repo_tag(options = {})
        display("Updating Repo Tag: #{options[:tag_name]}")
      end

      def push_repo(options = {})
        desc = "#{options[:reference_point]} to #{options[:app_name]} on Heroku"
        if options[:force]
          display("Force pushing #{desc}")
        else
          display("Pushing #{desc}")
        end
      end

      def run_migrations(options = {})
        display("Running database migrations")
      end

      def app_restart(options = {})
        display("Restarting application")
      end
    end
  end
end
