require 'forwardable'
require 'platform-api'

module Paratrooper
  class Slug
    extend Forwardable
    delegate [:system_caller] => :config

    attr_accessor :config

    def initialize(config)
      @config = config
    end

    def client(options = nil)
      PlatformAPI.connect(LocalApiKeyExtractor.get_credentials, options)
    end

    def slug_id_to_deploy
      if config.slug_id
        config.slug_id
      elsif config.slug_app_name
        deployed_slug(config.slug_app_name)
      else
        'UNKNOWN SLUG ID'
      end
    end

    def deployed_slug(app_name)
      options = {default_headers: {'Range' => 'version ..; order=desc,max=1;'}}
      client(options).release.list(app_name).first['slug']['id']
    end

    def deploy_slug
      client.release.create(config.app_name, {"slug"=> slug_id_to_deploy})
    end

    # Internal: Calls commands meant to go to system.
    #
    # cmd - String version of system command.
    #
    def system_call(cmd, exit_code = false)
      system_caller.execute(cmd, exit_code)
    end
  end
end
