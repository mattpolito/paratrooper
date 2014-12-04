require 'paratrooper/heroku_wrapper'
require 'paratrooper/http_client_wrapper'
require 'paratrooper/system_caller'
require 'paratrooper/callbacks'
require 'paratrooper/pending_migration_check'

module Paratrooper
  class Configuration
    include Callbacks

    attr_accessor :tag_name, :branch_name, :app_name, :api_key
    attr_writer :match_tag_name, :protocol, :heroku, :migration_check,
      :system_caller, :deployment_host, :http_client, :screen_notifier

    alias :branch= :branch_name=
    alias :match_tag= :match_tag_name=
    alias :tag= :tag_name=

    def attributes=(attrs)
      attrs.each do |method, value|
        public_send("#{method}=", value)
      end
    end

    def match_tag_name
      @match_tag_name ||= 'master'
    end

    def migration_check
      @migration_check ||= PendingMigrationCheck.new(match_tag_name, heroku, system_caller)
    end

    def heroku
      @heroku ||= HerokuWrapper.new(app_name)
    end

    def screen_notifier
      @screen_notifier ||= Notifiers::ScreenNotifier.new
    end

    def notifiers=(notifers)
      @notifiers = Array(notifers)
    end

    def notifiers
      @notifiers ||= [@screen_notifier]
    end

    # def force
    #   @force ||= false
    # end

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

    def maintenance=(val)
      @maintenance = !!val
    end

    def maintenance?
      @maintenance
    end

    def force_push=(val)
      @force_push= !!val
    end

    def force_push
      @force_push ||= false
    end

    def force_push?
      @force_push
    end

    def system_caller
      @system_caller ||= SystemCaller.new
    end
  end
end
