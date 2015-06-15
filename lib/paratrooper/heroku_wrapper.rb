require 'platform-api'
require 'rendezvous'
require 'paratrooper/local_api_key_extractor'
require 'paratrooper/error'

module Paratrooper
  class HerokuWrapper
    class ErrorNoAccess < Paratrooper::Error
      def initialize(name)
        msg = "It appears that you may not have access to #{name}"
        super(msg)
      end
    end

    attr_reader :api_key, :app_name, :heroku_api, :key_extractor, :rendezvous

    def initialize(app_name, options = {})
      @app_name      = app_name
      @key_extractor = options[:key_extractor] || LocalApiKeyExtractor
      @api_key       = options[:api_key] || key_extractor.get_credentials
      @heroku_api    = options[:heroku_api] || PlatformAPI.connect_oauth(api_key)
      @rendezvous    = options[:rendezvous] || Rendezvous
    end

    def app_restart
      client(:dyno, :restart_all, app_name)
    end

    def app_maintenance_off
      client(:app, :update, app_name, 'maintenance' => 'false')
    end

    def app_maintenance_on
      client(:app, :update, app_name, 'maintenance' => 'true')
    end

    def releases
      client(:release, :list, app_name)
    end

    def run_migrations
      run_task('rake db:migrate')
    end

    def run_task(task)
      payload = { 'command' => task, 'attach' => 'true' }
      data    = client(:dyno, :create, app_name, payload).body
      rendezvous.start(url: data['rendezvous_url'])
    end

    def last_deploy_commit
      last_release = releases.body.first
      return nil if last_release.nil?

      slug_data = client(:slug, :info, app_name, get_slug_id(last_release)).body
      slug_data.last['commit']
    end

    private

    def get_slug_id(release)
      release["slug"]["id"].to_i
    end

    def app_maintenance(flag)
      client(:post_app_maintenance, app_name, flag)
    end

    def client(delegatee, method, *args)
      heroku_api.public_send(delegatee).public_send(method, *args)
    rescue PlatformAPI::Excon::Errors::Forbidden => e
      raise ErrorNoAccess.new(app_name)
    end
  end
end
