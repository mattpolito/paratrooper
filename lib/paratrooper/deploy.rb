require 'paratrooper/heroku_wrapper'
require 'paratrooper/system_caller'
require 'paratrooper/notifiers/screen_notifier'

module Paratrooper

  # Public: Entry point into the library.
  #
  class Deploy
    attr_reader :app_name, :notifiers, :system_caller, :heroku, :tag_name,
      :match_tag, :callbacks

    # Public: Initializes a Deploy
    #
    # app_name - A String naming the Heroku application to be interacted with.
    # options  - The Hash options is used to provide additional functionality.
    #            :notifiers     - Array of objects interested in being notified
    #                             of steps in deployment process (optional).
    #            :heroku        - Object wrapper around heroku-api (optional).
    #            :tag           - String name to be used as a git reference
    #                             point (optional).
    #            :match_tag_to  - String name of git reference point to match
    #                             :tag to (optional).
    #            :system_caller - Object responsible for calling system
    #                             commands (optional).
    def initialize(app_name, options = {})
      @app_name      = app_name
      @notifiers     = options[:notifiers] || [Notifiers::ScreenNotifier.new]
      @heroku        = options[:heroku] || HerokuWrapper.new(app_name, options)
      @tag_name      = options[:tag]
      @match_tag     = options[:match_tag_to] || 'master'
      @system_caller = options[:system_caller] || SystemCaller.new
      @callbacks     = options[:callbacks] || []
    end
    
    def before(step, options={})
      callbacks.each do |callback|
        result = callback.run(step, default_payload.merge(options))
        return if result === false
      end
      yield if block_given?
    end

    def setup
      before(:setup) do
        notify(:setup)
      end
    end

    def teardown
      before(:teardown) do
        notify(:teardown)
      end
    end

    def notify(step, options={})
      notifiers.each do |notifier|
        notifier.notify(step, default_payload.merge(options))
      end
    end

    # Public: Activates Heroku maintenance mode.
    #
    def activate_maintenance_mode
      before(:activate_maintenance_mode) do
        notify(:activate_maintenance_mode)
        heroku.app_maintenance_on
      end
    end

    # Public: Deactivates Heroku maintenance mode.
    #
    def deactivate_maintenance_mode
      before(:deactivate_maintenance_mode) do
        notify(:deactivate_maintenance_mode)
        heroku.app_maintenance_off
      end
    end

    # Public: Creates a git tag and pushes it to repository.
    #
    def update_repo_tag
      unless tag_name.nil? || tag_name.empty?
        before(:update_repo_tag) do
          notify(:update_repo_tag)
          system_call "git tag #{tag_name} #{match_tag} -f"
          system_call "git push -f #{git_remote} #{tag_name}"
        end
      end
    end

    # Public: Pushes repository to Heroku.
    #
    def push_repo
      reference_point = tag_name || 'master'
      before(:push_repo, reference_point: reference_point) do
        notify(:push_repo, reference_point: reference_point)
        system_call "git push -f #{git_remote} #{reference_point}:master"
      end
    end

    # Public: Runs rails database migrations on your application.
    #
    def run_migrations
      before(:run_migrations) do
        notify(:run_migrations)
        system_call "heroku run rake db:migrate --app #{app_name}"
      end
    end

    # Public: Restarts application on Heroku.
    #
    def app_restart
      before(:app_restart) do
        notify(:app_restart)
        heroku.app_restart
      end
    end

    # Public: cURL for application URL to start your Heroku dyno.
    #
    def warm_instance(wait_time = 3)
      before(:warm_instance) do
        sleep wait_time
        notify(:warm_instance)
        system_call "curl -Il http://#{app_url}"
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

    private
    def app_url
      heroku.app_url
    end

    def default_payload
      {
        app_name: app_name,
        app_url: app_url,
        git_remote: git_remote,
        tag_name: tag_name,
        match_tag: match_tag
      }
    end

    def git_remote
      "git@heroku.com:#{app_name}.git"
    end

    # Internal: Calls commands meant to go to system
    #
    # call - String version of system command
    def system_call(call)
      system_caller.execute(call)
    end
  end
end
