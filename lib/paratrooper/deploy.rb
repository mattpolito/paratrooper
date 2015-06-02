require 'forwardable'
require 'paratrooper/configuration'
require 'paratrooper/error'

module Paratrooper
  class Deploy
    extend Forwardable

    delegate [:system_caller, :migration_check, :notifiers,
      :deloyment_host, :heroku, :source_control, :screen_notifier, :slug
    ] => :config

    attr_writer :config

    def self.call(app_name, options = {}, &block)
      new(app_name, options, &block).deploy
    end

    # Public: Initializes a Deploy
    #
    # app_name - A String naming the Heroku application to be interacted with.
    # options  - The Hash options is used to provide additional functionality.
    #            :screen_notifier - Object used for outputting to screen
    #                               (optional).
    #            :notifiers       - Array of objects interested in being
    #                               notified of steps in deployment process
    #                               (optional).
    #            :heroku          - Object wrapper around heroku-api (optional).
    #            :branch          - String name to be used as a git reference
    #                               point for deploying from specific branch.
    #                               Use :head to deploy from current branch
    #                               (optional).
    #            :force           - Force deploy using (-f flag) on deploy
    #                               (optional, default: false)
    #            :system_caller   - Object responsible for calling system
    #                               commands (optional).
    #            :protocol        - String web protocol to be used when pinging
    #                               application (optional, default: 'http').
    #            :deployment_host - String host name to be used in git URL
    #                               (optional, default: 'heroku.com').
    #            :migration_check - Object responsible for checking pending
    #                               migrations (optional).
    #            :maintenance     - If true, show maintenance page when pending
    #                               migrations exists. False by default (optional).
    #                               migrations (optional).
    #            :api_key         - String version of heroku api key.
    #                               (default: looks in local Netrc file).
    #            :http_client     - Object responsible for making http calls
    #                               (optional).
    #
    def initialize(app_name, options = {}, &block)
      config.attributes = options.merge(app_name: app_name)
      block.call(config) if block_given?
    end

    def config
      @config ||= Configuration.new
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
      notify(:deploy_finished)
    end

    def update_repo_tag
      if source_control.taggable?
        callback(:update_repo_tag) do
          notify(:update_repo_tag)
          source_control.update_repo_tag
        end
      end
    end

    # Public: Activates Heroku maintenance mode.
    #
    def activate_maintenance_mode
      return unless maintenance_necessary?
      callback(:activate_maintenance_mode) do
        notify(:activate_maintenance_mode)
        heroku.app_maintenance_on
      end
    end

    # Public: Deactivates Heroku maintenance mode.
    #
    def deactivate_maintenance_mode
      return unless maintenance_necessary?
      callback(:deactivate_maintenance_mode) do
        notify(:deactivate_maintenance_mode)
        heroku.app_maintenance_off
      end
    end

    # Public: Pushes repository to Heroku.
    #
    # Based on the following precedence:
    # branch_name / 'master'
    #
    def push_repo
      callback(:push_repo) do
        notify(:push_repo)
        source_control.push_to_deploy
      end
    end

    # Public: Pushes (deploys) the slug to Heroku
    #
    def push_slug
      callback(:push_slug) do
        notify(:push_slug)
        slug.deploy_slug
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

    # Public: Execute common deploy steps.
    #
    # Default deploy consists of:
    # * Activating maintenance page
    # * Pushing repository to Heroku
    # * Running database migrations
    # * Restarting application on Heroku
    # * Deactivating maintenance page
    #
    # Alias: #deploy
    def default_deploy
      setup
      update_repo_tag
      slug_deploy?() ? push_slug() : push_repo()
      maintenance_mode do
        run_migrations
        app_restart
      end
      teardown
    rescue Paratrooper::Error => e
      abort(e.message)
    end
    alias_method :deploy, :default_deploy

    # Public: Runs task on your heroku instance.
    #
    # task_name - String name of task to run on heroku instance
    #
    def add_remote_task(task_name)
      heroku.run_task(task_name)
    end

    # Public: Return the slug id of the last release of app_name
    #
    # app_name - String name of the app to lookup slug id
    #
    def deployed_slug(app_name)
      slug.deployed_slug(app_name)
    end

    private
    def maintenance_mode(&block)
      activate_maintenance_mode
      block.call if block_given?
      deactivate_maintenance_mode
    end

    def maintenance_necessary?
      config.maintenance? && pending_migrations?
    end

    def callback(name, &block)
      config.build_callback(name, screen_notifier, &block)
    end

    # Internal: Payload data to be sent with notifications
    #
    def default_payload
      {
        app_name: config.app_name,
        deployment_remote: deployment_remote,
        force_push: config.force_push,
        reference_point: source_control.reference_point,
        slug_id: slug.slug_id_to_deploy
      }
    end

    def deployment_remote
      source_control.remote
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
      @pending_migrations ||= migration_check.migrations_waiting?
    end

    def restart_required?
      pending_migrations?
    end

    def slug_deploy?
      if config.slug_id || config.slug_app_name
        true
      else
        false
      end
    end
  end
end
