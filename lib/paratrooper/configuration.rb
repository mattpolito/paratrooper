# require 'paratrooper/heroku_wrapper'
require 'paratrooper/http_client_wrapper'
require 'paratrooper/system_caller'
require 'paratrooper/callbacks'

module Paratrooper
  class Configuration
    include Callbacks

    attr_accessor :app_name, :tag_name, :branch_name, :maintenance_mode
    attr_writer :api_key, :deployment_host, :force, :heroku_wrapper,
      :http_client, :maintenance, :match_tag_name, :migration_check,
      :protocol, :screen_notifier, :system_caller

    alias :branch= :branch_name=
    alias :match_tag= :match_tag_name=
    alias :tag= :tag_name=
    alias :heroku_auth= :heroku_wrapper=

    def attributes=(attrs)
      attrs.each do |method, value|
        public_send("#{method}=", value)
      end
    end

    def match_tag_name
      @match_tag_name ||= 'master'
    end

    def migration_check
      @migration_check ||= PendingMigrationCheck.new(match_tag_name, heroku_wrapper, system_caller)
    end

    def heroku_wrapper
      @heroku_wrapper ||= HerokuWrapper.new(app_name, options.merge(api_key: api_key))
    end
    alias :heroku :heroku_wrapper

    def screen_notifier
      @screen_notifier ||= Notifiers::ScreenNotifier.new
    end

    def notifiers=(notifers)
      @notifiers = Array(notifers)
    end

    def notifiers
      @notifiers ||= [@screen_notifier]
    end

    def force
      @force ||= false
    end

    def protocol
      @protocol ||= 'http'
    end

    def deployment_host
      @deployment_host ||= 'heroku.com'
    end

    def http_client
      @http_client ||= HttpClientWrapper.new
    end

    def maintenance
      @maintenance ||= false
    end

    def api_key
      @api_key ||= nil
    end

    def system_caller
      @system_caller ||= SystemCaller.new
    end
  end
end
