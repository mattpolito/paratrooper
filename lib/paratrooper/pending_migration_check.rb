require 'paratrooper/system_caller'

module Paratrooper
  class PendingMigrationCheck
    attr_accessor :diff, :last_deployed_commit, :deployment_sha, :system_caller

    def initialize(last_deployed_commit, deployment_sha, system_caller)
      self.last_deployed_commit = last_deployed_commit
      self.deployment_sha = deployment_sha
      self.system_caller  = system_caller
    end

    def migrations_waiting?
      defined?(@migrations_waiting) or @migrations_waiting = check_for_pending_migrations
      @migrations_waiting
    end

    private

    def check_for_pending_migrations
      cmd = %Q[git diff --shortstat #{last_deployed_commit} #{deployment_sha} -- db/migrate]
      self.diff = system_caller.execute(cmd)
      !diff.strip.empty?
    end
  end
end
