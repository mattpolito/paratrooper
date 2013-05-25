require 'paratrooper/system_caller'

module Paratrooper
  class PendingMigrationCheck
    attr_accessor :diff, :heroku, :match_tag_name, :system_caller

    def initialize(match_tag_name, heroku_wrapper, system_caller)
      self.heroku         = heroku_wrapper
      self.match_tag_name = match_tag_name
      self.system_caller  = system_caller
      last_deployed_commit
    end

    def migrations_waiting?
      call = %Q[git diff --shortstat #{last_deployed_commit} #{match_tag_name} -- db/migrate]
      self.diff = system_caller.execute(call)
      !diff.strip.empty?
    end

    def last_deployed_commit
      @last_deploy_commit ||= heroku.last_deploy_commit
    end
  end
end
