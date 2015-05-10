require 'spec_helper'
require 'paratrooper/configuration'
require 'paratrooper/source_control'

describe Paratrooper::SourceControl do
  describe "remote" do
    it "returns string of git representing remote repo" do
      config = instance_double(Paratrooper::Configuration,
        deployment_host: 'HOST', app_name: 'APP'
      )
      source_control = described_class.new(config)

      expect(source_control.remote).to eq("git@HOST:APP.git")
    end
  end

  describe "force_flag" do
    context "when force_push is truthy" do
      it "returns string representing a force flag in git" do
        config = instance_double(Paratrooper::Configuration, force_push: true)
        source_control = described_class.new(config)

        expect(source_control.force_flag).to eq("-f ")
      end
    end

    context "when force_push is falsey" do
      it "returns nil" do
        config = instance_double(Paratrooper::Configuration, force_push: false)
        source_control = described_class.new(config)

        expect(source_control.force_flag).to be_nil
      end
    end
  end

  describe "branch_name" do
    context "when branch name is available" do
      context "and is the symbol :head" do
        it "returns string representing HEAD" do
          config = instance_double(Paratrooper::Configuration,
            branch_name?: true, branch_name: :head
          )
          source_control = described_class.new(config)

          expect(source_control.branch_name).to eq("HEAD")
        end
      end

      context "and is the string head" do
        it "returns string representing HEAD" do
          config = instance_double(Paratrooper::Configuration,
            branch_name?: true, branch_name: 'head'
          )
          source_control = described_class.new(config)

          expect(source_control.branch_name).to eq("HEAD")
        end
      end

      context "and contains any string name" do
        it "returns string representing fully qualified branch path" do
          config = instance_double(Paratrooper::Configuration,
            branch_name?: true, branch_name: 'BRANCH_NAME'
          )
          source_control = described_class.new(config)

          expect(source_control.branch_name).to eq("refs/heads/BRANCH_NAME")
        end
      end
    end

    context "when branch name is not available" do
      it "returns nil" do
        config = instance_double(Paratrooper::Configuration,
          branch_name?: false
        )
        source_control = described_class.new(config)

        expect(source_control.branch_name).to be_nil
      end
    end
  end

  describe "deployment_sha" do
    it "returns sha" do
      system_caller = double(:system_caller)
      allow(system_caller).to receive(:execute).and_return("SHA\n")
      config = instance_double(Paratrooper::Configuration,
        branch_name?: false, system_caller: system_caller
      )
      source_control = described_class.new(config)
      expect(source_control.deployment_sha).to eq("SHA")
    end

    context "when branch_name is available" do
      it "requests git to find sha from branch" do
        system_caller = double(:system_caller)
        allow(system_caller).to receive(:execute).and_return("SHA\n")
        config = instance_double(Paratrooper::Configuration,
          branch_name?: true, branch_name: "BRANCH_NAME",
          system_caller: system_caller
        )
        source_control = described_class.new(config)

        source_control.deployment_sha
        expected_cmd = ["git rev-parse refs/heads/BRANCH_NAME", false]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end

    context "when branch_name is unavailable" do
      it "requests git to find sha from branch" do
        system_caller = double(:system_caller)
        allow(system_caller).to receive(:execute).and_return("SHA\n")
        config = instance_double(Paratrooper::Configuration,
          branch_name?: false, system_caller: system_caller
        )
        source_control = described_class.new(config)

        source_control.deployment_sha
        expected_cmd = ["git rev-parse HEAD", false]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end
  end

  describe "update_repo_tag" do
    let(:system_caller) { double(:system_caller) }

    before do
      allow(system_caller).to receive(:execute)
    end

    it "issues command to create/update & push tag based on tag name" do
      config = instance_double(Paratrooper::Configuration,
        system_caller: system_caller,
        tag_name: 'TAG',
        match_tag_name: 'MATCH_TAG'
      )
      source_control = described_class.new(config)
      source_control.update_repo_tag

      expected_cmd = ["git tag TAG MATCH_TAG -f", false]
      expect(system_caller).to have_received(:execute).with(*expected_cmd)
    end
  end

  describe "push_to_deploy" do
    let(:system_caller) { double(:system_caller) }

    before do
      allow(system_caller).to receive(:execute)
    end

    context "when branch_name is a string" do
      it 'pushes branch_name' do
        config = instance_double(Paratrooper::Configuration, force_push: false,
          deployment_host: "HOST", app_name: "APP", branch_name?: true,
          branch_name: "BRANCH_NAME", system_caller: system_caller
        )
        source_control = described_class.new(config)
        source_control.push_to_deploy

        expected_cmd = ['git push git@HOST:APP.git refs/heads/BRANCH_NAME:refs/heads/master', :exit_code]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end

    context "when branch_name is a symbol" do
      it 'pushes branch_name' do
        config = instance_double(Paratrooper::Configuration, force_push: false,
          deployment_host: "HOST", app_name: "APP", branch_name?: true,
          branch_name: :BRANCH_NAME, system_caller: system_caller
        )
        source_control = described_class.new(config)
        source_control.push_to_deploy

        expected_cmd = ['git push git@HOST:APP.git refs/heads/BRANCH_NAME:refs/heads/master', :exit_code]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end

    context "when branch_name is :head" do
      it 'pushes HEAD' do
        config = instance_double(Paratrooper::Configuration, force_push: false,
          deployment_host: "HOST", app_name: "APP", branch_name?: true,
          branch_name: :head, system_caller: system_caller
        )
        source_control = described_class.new(config)
        source_control.push_to_deploy

        expected_cmd = ['git push git@HOST:APP.git HEAD:refs/heads/master', :exit_code]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end

    context "when branch_name is the string HEAD" do
      it 'pushes HEAD' do
        config = instance_double(Paratrooper::Configuration, force_push: false,
          deployment_host: "HOST", app_name: "APP", branch_name?: true,
          branch_name: "HEAD", system_caller: system_caller
        )
        source_control = described_class.new(config)
        source_control.push_to_deploy

        expected_cmd = ['git push git@HOST:APP.git HEAD:refs/heads/master', :exit_code]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end

    context "when choosing to force push" do
      it "issues command to forcefully push to remote" do
        config = instance_double(Paratrooper::Configuration,
          system_caller: system_caller, force_push: true,
          deployment_host: 'HOST', app_name: 'APP', branch_name?: false
        )
        source_control = described_class.new(config)
        source_control.push_to_deploy

        expected_cmd = ["git push -f git@HOST:APP.git HEAD:refs/heads/master", :exit_code]
        expect(config.system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end

    context "when branch_name is available" do
      it "pushes branch_name" do
        config = instance_double(Paratrooper::Configuration, force_push: false,
          deployment_host: "HOST", app_name: "APP", branch_name?: true,
          branch_name: "BRANCH_NAME", system_caller: system_caller
        )
        source_control = described_class.new(config)
        source_control.push_to_deploy

        expected_cmd = ['git push git@HOST:APP.git refs/heads/BRANCH_NAME:refs/heads/master', :exit_code]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end

    context "when no reference is defined" do
      it "pushes HEAD" do
        config = instance_double(Paratrooper::Configuration, force_push: false,
          deployment_host: "HOST", app_name: "APP", branch_name?: false,
          system_caller: system_caller
        )
        source_control = described_class.new(config)
        source_control.push_to_deploy

        expected_cmd = ['git push git@HOST:APP.git HEAD:refs/heads/master', :exit_code]
        expect(system_caller).to have_received(:execute).with(*expected_cmd)
      end
    end
  end

  describe "#scm_tag_reference" do
    context "when tag_name is available" do
      it "returns fully qualified tag name" do
        config = instance_double(Paratrooper::Configuration, tag_name: "TAG")
        source_control = described_class.new(config)
        expect(source_control.scm_tag_reference).to eq("refs/tags/TAG")
      end
    end

    context "when tag_name is unavailable" do
      it "returns nil" do
        config = instance_double(Paratrooper::Configuration, tag_name: nil)
        source_control = described_class.new(config)
        expect(source_control.scm_tag_reference).to be_nil
      end
    end
  end

  describe "#scm_match_reference" do
    context "when match_tag_name is available" do
      it "returns fully qualified tag name" do
        config = instance_double(Paratrooper::Configuration, match_tag_name: "MATCH_TAG")
        source_control = described_class.new(config)
        expect(source_control.scm_match_reference).to eq("refs/tags/MATCH_TAG")
      end
    end

    context "when match_tag_name is unavailable" do
      it "returns HEAD" do
        config = instance_double(Paratrooper::Configuration, match_tag_name: nil)
        source_control = described_class.new(config)
        expect(source_control.scm_match_reference).to eq("HEAD")
      end
    end
  end
end
