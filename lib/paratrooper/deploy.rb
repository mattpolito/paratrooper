require 'paratrooper/heroku_wrapper'
require 'paratrooper/system_caller'
require 'paratrooper/notifiers/screen_notifier'
require 'paratrooper/pending_migration_check'

module Paratrooper

  # Public: Entry point into the library.
  #
  class Deploy
    attr_reader :app_name, :notifiers, :system_caller, :heroku, :tag_name,
      :match_tag, :protocol, :deployment_host, :migration_check, :debug

    # Public: Initializes a Deploy
    #
    # app_name - A String naming the Heroku application to be interacted with.
    # options  - The Hash options is used to provide additional functionality.
    #            :notifiers       - Array of objects interested in being
    #                               notified of steps in deployment process
    #                               (optional).
    #            :heroku          - Object wrapper around heroku-api (optional).
    #            :tag             - String name to be used as a git reference
    #                               point (optional).
    #            :match_tag_to    - String name of git reference point to match
    #                               :tag to (optional).
    #            :system_caller   - Object responsible for calling system
    #                               commands (optional).
    #            :protocol        - String web protocol to be used when pinging
    #                               application (optional, default: 'http').
    #            :deployment_host - String host name to be used in git URL
    #                               (optional, default: 'heroku.com').
    #            :migration_check - Object responsible for checking pending
    #                               migrations (optional).
    #            :use_maintenance_mode - Boolean whether to trigger maintenance
    #                               mode on and off during deployment (default:
    #                               true)
    def initialize(app_name, options = {})
      @app_name        = app_name
      @notifiers       = options[:notifiers] || [Notifiers::ScreenNotifier.new]
      @heroku          = options[:heroku] || HerokuWrapper.new(app_name, options)
      @tag_name        = options[:tag]
      @match_tag       = options[:match_tag_to] || 'master'
      @system_caller   = options[:system_caller] || SystemCaller.new(debug)
      @protocol        = options[:protocol] || 'http'
      @deployment_host = options[:deployment_host] || 'heroku.com'
      @debug           = options[:debug] || false
      @use_maintenance_mode = options.fetch(:use_maintenance_mode, true)
      self.migration_check = options[:migration_check]
    end

    def setup
      notify(:setup)
    end

    def teardown
      notify(:teardown)
    end

    def notify(step, options={})
      notifiers.each do |notifier|
        notifier.notify(step, default_payload.merge(options))
      end
    end

    # Public: Activates Heroku maintenance mode.
    #
    def activate_maintenance_mode
      return unless use_maintenance_mode?
      notify(:activate_maintenance_mode)
      heroku.app_maintenance_on
    end

    # Public: Deactivates Heroku maintenance mode.
    #
    def deactivate_maintenance_mode
      return unless use_maintenance_mode?
      notify(:deactivate_maintenance_mode)
      heroku.app_maintenance_off
    end

    # Public: Creates a git tag and pushes it to repository.
    #
    def update_repo_tag
      unless tag_name.nil? || tag_name.empty?
        notify(:update_repo_tag)
        system_call "git tag #{tag_name} #{match_tag} -f"
        system_call "git push -f origin #{tag_name}"
      end
    end

    # Public: Pushes repository to Heroku.
    #
    def push_repo
      reference_point = tag_name || 'master'
      notify(:push_repo, reference_point: reference_point)
      system_call "git push -f #{deployment_remote} #{reference_point}:refs/heads/master"
    end

    # Public: Runs rails database migrations on your application.
    #
    def run_migrations
      return unless pending_migrations?
      notify(:run_migrations)
      heroku.run_migrations
    end

    # Public: Restarts application on Heroku.
    #
    def app_restart
      notify(:app_restart)
      heroku.app_restart
    end

    # Public: cURL for application URL to start your Heroku dyno.
    #
    def warm_instance(wait_time = 3)
      sleep wait_time
      notify(:warm_instance)
      system_call "curl -Il #{protocol}://#{app_url}"
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

    def use_maintenance_mode?
      !!@use_maintenance_mode
    end

    private
    def app_url
      heroku.app_url
    end

    def default_payload
      {
        app_name: app_name,
        app_url: app_url,
        deployment_remote: deployment_remote,
        tag_name: tag_name,
        match_tag: match_tag
      }
    end

    def git_remote(host, name)
      "git@#{host}:#{name}.git"
    end

    def deployment_remote
      git_remote(deployment_host, app_name)
    end

    def pending_migrations?
      migration_check.migrations_waiting?
    end

    def migration_check=(obj)
      @migration_check = obj || PendingMigrationCheck.new(match_tag, heroku, system_caller)
      @migration_check.last_deployed_commit
      @migration_check
    end

    # Internal: Calls commands meant to go to system
    #
    # call - String version of system command
    def system_call(call)
      system_caller.execute(call)
    end
  end
end
