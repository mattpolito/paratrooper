require 'heroku-api'
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
      @heroku_api    = options[:heroku_api] || Heroku::API.new(api_key: api_key)
      @rendezvous    = options[:rendezvous] || Rendezvous
    end

    def app_restart
      client(:post_ps_restart, app_name)
    end

    def app_maintenance_off
      app_maintenance('0')
    end

    def app_maintenance_on
      app_maintenance('1')
    end

    def run_migrations
      run_task('rake db:migrate')
    end

    def run_task(task_name)
      data = client(:post_ps, app_name, task_name, attach: 'true').body
      rendezvous.start(url: data['rendezvous_url'])
    end

    def last_deployed_commit
      data = client(:get_releases, app_name).body
      return nil if data.empty?
      data.last['commit']
    end

    private
    def app_maintenance(flag)
      client(:post_app_maintenance, app_name, flag)
    end

    def client(method, *args)
      heroku_api.public_send(method, *args)
    rescue Heroku::API::Errors::Forbidden => e
      raise ErrorNoAccess.new(app_name)
    end
  end
end
