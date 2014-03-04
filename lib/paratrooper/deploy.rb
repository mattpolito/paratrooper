require 'paratrooper/heroku_wrapper'
require 'paratrooper/system_caller'
require 'paratrooper/notifiers/screen_notifier'
require 'paratrooper/pending_migration_check'
require 'paratrooper/callbacks'

module Paratrooper

  # Public: Entry point into the library.
  #
  class Deploy
    include Callbacks

    attr_accessor :app_name, :notifiers, :system_caller, :heroku, :protocol,
                  :deployment_host, :migration_check, :debug, :screen_notifier
    attr_writer   :tag_name, :match_tag_name

    alias_method :tag=, :tag_name=
    alias_method :match_tag=, :match_tag_name=

    # Public: Initializes a Deploy
    #
    # app_name - A String naming the Heroku application to be interacted with.
    # options  - The Hash options is used to provide additional functionality.
    #            :screen_notifier  - Object used for outputting to screen
    #                                (optional).
    #            :notifiers        - Array of objects interested in being
    #                                notified of steps in deployment process
    #                                (optional).
    #            :heroku           - Object wrapper around heroku-api (optional).
    #            :tag              - String name to be used as a git reference
    #                                point (optional).
    #            :match_tag        - String name of git reference point to
    #                                match, it can be a branch, tag or SHA1
    #                                (optional).
    #            :system_caller    - Object responsible for calling system
    #                                commands (optional).
    #            :protocol         - String web protocol to be used when pinging
    #                                application (optional, default: 'http').
    #            :deployment_host  - String host name to be used in git URL
    #                                (optional, default: 'heroku.com').
    #            :migration_check  - Object responsible for checking pending
    #                                migrations (optional).
    #            :api_key          - String version of heroku api key.
    #                                (default: looks in local Netrc file).
    def initialize(app_name, options = {}, &block)
      @app_name        = app_name
      @screen_notifier = options[:screen_notifier] || Notifiers::ScreenNotifier.new
      @notifiers       = options[:notifiers] || [@screen_notifier]
      @heroku          = options[:heroku] || HerokuWrapper.new(app_name, options)
      @tag_name        = options[:tag]
      @match_tag_name  = options[:match_tag]
      @system_caller   = options[:system_caller] || SystemCaller.new(debug)
      @protocol        = options[:protocol] || 'http'
      @deployment_host = options[:deployment_host] || 'heroku.com'
      @debug           = options[:debug] || false
      @migration_check = options[:migration_check] || PendingMigrationCheck.new(match_tag_name, heroku, system_caller)

      block.call(self) if block_given?
    end

    # Public: Hook method called first in the deploy process.
    #
    def setup
      callback(:setup) do
        notify(:setup)
        migration_check.last_deployed_commit
      end
    end

    # Public: Hook method called last in the deploy process.
    #
    def teardown
      callback(:teardown) do
        notify(:teardown)
      end
    end

    # Public: Activates Heroku maintenance mode.
    #
    def activate_maintenance_mode
      return unless pending_migrations?
      callback(:activate_maintenance_mode) do
        notify(:activate_maintenance_mode)
        heroku.app_maintenance_on
      end
    end

    # Public: Deactivates Heroku maintenance mode.
    #
    def deactivate_maintenance_mode
      return unless pending_migrations?
      callback(:deactivate_maintenance_mode) do
        notify(:deactivate_maintenance_mode)
        heroku.app_maintenance_off
      end
    end

    # Public: Creates a git tag and pushes it to repository.
    #
    def update_repo_tag
      if tag_name
        callback(:update_repo_tag) do
          notify(:update_repo_tag)
          commit_to_match = match_tag_name || current_branch_head
          system_call "git tag #{tag_name} #{commit_to_match} -f"
          system_call "git push -f origin #{tag_name}"
        end
      end
    end

    # Public: Pushes repository to Heroku.
    #
    def push_repo
      callback(:push_repo) do
        reference_point = tag_name || match_tag_name || current_branch_head
        notify(:push_repo, reference_point: reference_point)
        system_call "git push -f #{deployment_remote} #{reference_point}:refs/heads/master"
      end
    end

    # Public: Runs rails database migrations on your application.
    #
    def run_migrations
      return unless pending_migrations?
      callback(:run_migrations) do
        notify(:run_migrations)
        heroku.run_migrations
      end
    end

    # Public: Restarts application on Heroku.
    #
    def app_restart
      return unless restart_required?
      callback(:app_restart) do
        notify(:app_restart)
        heroku.app_restart
      end
    end

    # Public: cURL for application URL to start your Heroku dyno.
    #
    # wait_time - Integer length of time (seconds) to wait before making call
    #             to app
    #
    def warm_instance(wait_time = 3)
      callback(:warm_instance) do
        notify(:warm_instance)
        sleep wait_time
        system_call "curl -Il #{protocol}://#{app_url}"
      end
    end

    # Public: Execute common deploy steps.
    #
    # Default deploy consists of:
    # * Activating maintenance page
    # * Updating repository tag
    # * Pushing repository to Heroku
    # * Running database migrations
    # * Restarting application on Heroku
    # * Deactivating maintenance page
    # * cURL'ing application URL to warm Heroku dyno
    #
    # Alias: #deploy
    def default_deploy
      setup
      activate_maintenance_mode
      update_repo_tag
      push_repo
      run_migrations
      app_restart
      deactivate_maintenance_mode
      warm_instance
      teardown
    end
    alias_method :deploy, :default_deploy

    # Public: Runs task on your heroku instance.
    #
    # task_name - String name of task to run on heroku instance
    #
    def add_remote_task(task_name)
      heroku.run_task(task_name)
    end

    # Public: Returns the name of the tag name if present
    #
    def tag_name
      return @tag_name if !@tag_name.nil? && !@tag_name.empty?
      nil
    end

    # Public: Returns the name of the tag name to match if present
    #
    def match_tag_name
      return @match_tag_name if !@match_tag_name.nil? && !@match_tag_name.empty?
      nil
    end

    private
    def app_url
      heroku.app_url
    end

    def callback(name, &block)
      build_callback(name, screen_notifier, &block)
    end

    # Internal: Payload data to be sent with notifications
    #
    def default_payload
      {
        app_name: app_name,
        app_url: app_url,
        deployment_remote: deployment_remote,
        tag_name: tag_name,
        match_tag: match_tag_name
      }
    end

    def git_remote(host, name)
      "git@#{host}:#{name}.git"
    end

    def deployment_remote
      git_remote(deployment_host, app_name)
    end

    # Internal: Notifies other objects that an event has occurred
    #
    # step    - String event name
    # options - Hash of options to be sent as data payload
    #
    def notify(step, options = {})
      notifiers.each do |notifier|
        notifier.notify(step, default_payload.merge(options))
      end
    end

    def pending_migrations?
      migration_check.migrations_waiting?
    end

    def restart_required?
      pending_migrations?
    end

    # Internal: Calls commands meant to go to system
    #
    # call - String version of system command
    #
    def system_call(call)
      system_caller.execute(call).chomp
    end

    # Internal: Gets HEAD of the current branch
    #
    def current_branch_head
      system_call "git rev-parse --abbrev-ref HEAD"
    end
  end
end
