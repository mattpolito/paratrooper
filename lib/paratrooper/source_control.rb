require 'forwardable'

module Paratrooper
  class SourceControl
    extend Forwardable
    delegate [:system_caller] => :config

    attr_accessor :config

    def initialize(config)
      @config = config
    end

    def remote
      "git@#{config.deployment_host}:#{config.app_name}.git"
    end

    def branch_name
      if config.branch_name?
        branch = config.branch_name.to_s
        branch.upcase == "HEAD" ? "HEAD" : "refs/heads/#{config.branch_name}"
      end
    end

    def push_to_deploy
      system_call("git push #{force_flag}#{remote} #{reference_point}:refs/heads/master", :exit_code)
    end

    def reference_point
      branch_name || 'HEAD'
    end

    def deployment_sha
      system_call("git rev-parse #{reference_point}").strip
    end

    def force_flag
      "-f " if config.force_push
    end

    # Internal: Calls commands meant to go to system
    #
    # cmd - String version of system command
    #
    def system_call(cmd, exit_code = false)
      system_caller.execute(cmd, exit_code)
    end
  end
end
