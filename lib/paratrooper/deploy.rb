require 'paratrooper/callbacks'
require 'paratrooper/heroku_wrapper'
require 'paratrooper/system_caller'
require 'paratrooper/notifiers/screen_notifier'

module Paratrooper

  # Public: Entry point into the library.
  #
  class Deploy
    include Paratrooper::Callbacks

    attr_reader :app_name, :notifiers, :system_caller, :heroku, :tag_name,
      :match_tag, :protocol, :callbacks

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
    #            :protocol      - String web protocol to be used when pinging
    #                             application (optional, default: 'http').
    def initialize(app_name, options = {})
      @app_name      = app_name
      @notifiers     = options[:notifiers] || [Notifiers::ScreenNotifier.new]
      @heroku        = options[:heroku] || HerokuWrapper.new(app_name, options)
      @tag_name      = options[:tag]
      @match_tag     = options[:match_tag_to] || 'master'
      @system_caller = options[:system_caller] || SystemCaller.new
      @protocol      = options[:protocol] || 'http'
      @callbacks     = options[:callbacks] || []
      add_callbacks(@notifiers)
      add_callbacks(@callbacks)
    end
    
    def reference_point
      @reference_point ||= tag_name || 'master'
    end
    
    def setup
      run_callbacks :setup
    end

    def teardown
      run_callbacks :teardown
    end

    # Public: Activates Heroku maintenance mode.
    #
    def activate_maintenance_mode
      run_callbacks :activate_maintenance_mode do
        heroku.app_maintenance_on
      end
    end

    # Public: Deactivates Heroku maintenance mode.
    #
    def deactivate_maintenance_mode
      run_callbacks :deactivate_maintenance_mode do
        heroku.app_maintenance_off
      end
    end

    # Public: Creates a git tag and pushes it to repository.
    #
    def update_repo_tag
      unless tag_name.nil? || tag_name.empty?
        run_callbacks :update_repo_tag do
          system_call "git tag #{tag_name} #{match_tag} -f"
          system_call "git push -f #{git_remote} #{tag_name}"
        end
      end
    end

    # Public: Pushes repository to Heroku.
    #
    def push_repo
      run_callbacks :push_repo do
        system_call "git push -f #{git_remote} #{reference_point}:master"
      end
    end

    # Public: Runs rails database migrations on your application.
    #
    def run_migrations
      run_callbacks :run_migrations do
        system_call "heroku run rake db:migrate --app #{app_name}"
      end
    end

    # Public: Restarts application on Heroku.
    #
    def app_restart
      run_callbacks :app_restart do
        heroku.app_restart
      end
    end

    # Public: cURL for application URL to start your Heroku dyno.
    #
    def warm_instance(wait_time = 3)
      run_callbacks :warm_instance do
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
        match_tag: match_tag,
        reference_point: reference_point
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
