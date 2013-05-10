require 'spec_helper'
require 'paratrooper/pending_migration_check'

describe Paratrooper::PendingMigrationCheck do
  let(:migration_check) do
    described_class.new(match_tag_name, heroku_wrapper, system_caller)
  end
  let(:system_caller) { double(:system_caller) }
  let(:heroku_wrapper) do
    double(:heroku_wrapper, last_deploy_commit: last_deployed_commit)
  end
  let(:last_deployed_commit) { nil }

  describe "#migrations_waiting?" do
    let(:match_tag_name) { "MATCH" }
    let(:last_deployed_commit) { "LAST_DEPLOYED_COMMIT" }

    it "calls out to heroku for latest deploy's commit" do
      system_caller.stub(:execute).and_return("")
      heroku_wrapper.should_receive(:last_deploy_commit)
      migration_check.migrations_waiting?
    end

    context "and migrations are in diff" do
      it "returns true" do
        expected_call = %Q[git diff --shortstat LAST_DEPLOYED_COMMIT MATCH -- db/migrate]
        system_caller.should_receive(:execute).with(expected_call)
          .and_return("DIFF")
        expect(migration_check.migrations_waiting?).to be_true
      end
    end

    context "and migrations are not in diff" do
      let(:match_tag_name) { 'master' }
      let(:last_deployed_commit) { "LAST_DEPLOYED_COMMIT" }

      it "returns false" do
        expected_call = %Q[git diff --shortstat LAST_DEPLOYED_COMMIT master -- db/migrate]
        system_caller.should_receive(:execute).with(expected_call)
          .and_return("")
        expect(migration_check.migrations_waiting?).to be_false
      end
    end
  end
end
