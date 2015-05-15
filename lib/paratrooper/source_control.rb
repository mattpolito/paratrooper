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
      tag_name || branch_name || 'HEAD'
    end

    def deployment_sha
      system_call("git rev-parse #{reference_point}").strip
    end

    def force_flag
      "-f " if config.force_push
    end

    def tag_name
      config.tag_name
    end

    def taggable?
      !untaggable?
    end

    def untaggable?
      tag_name.nil? || tag_name.empty?
    end

    def match_tag_name
      config.match_tag_name
    end

    def scm_tag_reference
      "refs/tags/#{tag_name}" if tag_name
    end

    def scm_match_reference
      if match_tag_name
        "refs/tags/#{match_tag_name}"
      else
        "HEAD"
      end
    end

    def update_repo_tag
      system_call("git tag #{tag_name} #{match_tag_name} -f")
      system_call("git push -f origin #{scm_tag_reference}")
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
