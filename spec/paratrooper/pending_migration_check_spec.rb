require 'spec_helper'
require 'paratrooper/pending_migration_check'

describe Paratrooper::PendingMigrationCheck do
  let(:migration_check) do
    described_class.new(last_deployed_commit, match_tag_name, system_caller)
  end
  let(:system_caller) { double(:system_caller) }
  let(:last_deployed_commit) { nil }

  describe "#migrations_waiting?" do
    let(:match_tag_name) { "MATCH" }
    let(:last_deployed_commit) { "LAST_DEPLOYED_COMMIT" }

    it "memoizes the git diff" do
      expect(system_caller).to receive(:execute).exactly(1).times.and_return("DIFF")
      migration_check.migrations_waiting?
      migration_check.migrations_waiting?
    end

    it "memoizes the git diff when empty" do
      expect(system_caller).to receive(:execute).exactly(1).times.and_return("")
      migration_check.migrations_waiting?
      migration_check.migrations_waiting?
    end

    context "and migrations are in diff" do
      it "returns true" do
        expected_call = %Q[git diff --shortstat LAST_DEPLOYED_COMMIT MATCH -- db/migrate]
        expect(system_caller).to receive(:execute).with(expected_call)
          .and_return("DIFF")
        expect(migration_check.migrations_waiting?).to be(true)
      end
    end

    context "and migrations are not in diff" do
      let(:match_tag_name) { 'master' }
      let(:last_deployed_commit) { "LAST_DEPLOYED_COMMIT" }

      it "returns false" do
        expected_call = %Q[git diff --shortstat LAST_DEPLOYED_COMMIT master -- db/migrate]
        expect(system_caller).to receive(:execute).with(expected_call)
          .and_return("")
        expect(migration_check.migrations_waiting?).to be(false)
      end
    end
  end
end
