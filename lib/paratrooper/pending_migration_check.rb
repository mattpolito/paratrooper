require 'paratrooper/system_caller'

module Paratrooper
  class PendingMigrationCheck
    attr_accessor :diff, :heroku, :deployment_sha, :system_caller

    def initialize(deployment_sha, heroku_wrapper, system_caller)
      self.heroku         = heroku_wrapper
      self.deployment_sha = deployment_sha
      self.system_caller  = system_caller
    end

    def migrations_waiting?
      defined?(@migrations_waiting) or @migrations_waiting = check_for_pending_migrations
      @migrations_waiting
    end

    def last_deployed_commit
      @last_deploy_commit ||= heroku.last_deploy_commit
    end

    private

    def check_for_pending_migrations
      call = %Q[git diff --shortstat #{last_deployed_commit} #{deployment_sha} -- db/migrate]
      self.diff = system_caller.execute(call)
      !diff.strip.empty?
    end
  end
end
