require 'spec_helper'
require 'paratrooper/callbacks'

describe Paratrooper::Callbacks do
  class MockDeploy
    Paratrooper::Callbacks::HOOKS.each do |method|
      define_method(method){ }
    end

    def deploy
      push_repo
      run_migrations
    end

    include Paratrooper::Callbacks
  end

  let(:deploy) { MockDeploy.new }

  describe 'config' do
    it 'has no callbacks on initiliaze' do
      deploy.callbacks.empty?.should be_true
    end

    it 'stores before callbacks' do
      deploy.before :push_repo, :some_command
      deploy.callbacks[:before].should == { push_repo: [:some_command] }
    end

    it 'stores after callbacks' do
      deploy.after :push_repo, :some_command
      deploy.callbacks[:after].should == { push_repo: [:some_command] }
    end

    it 'stores callbacks associated to each method' do
      deploy.before :push_repo, :some_command
      deploy.before :push_repo, :other_command
      deploy.callbacks[:before].should == { push_repo: [:some_command, :other_command] }

      deploy.after :push_repo, :some_command
      deploy.after :push_repo, :other_command
      deploy.callbacks[:after].should == { push_repo: [:some_command, :other_command] }
    end
  end

  describe 'executing' do
    before do
      deploy.stub(:`).and_return([1, 2, 3])
    end

    it 'callbacks for each method with before' do
      deploy.should_receive(:`).exactly(2).times.and_return(1, 2)
      deploy.before :push_repo, "echo '1'"
      deploy.before :push_repo, "echo '2'"
      deploy.execute_callbacks_for(:push_repo, :before)
    end

    it 'callbacks for each method with after' do
      deploy.should_receive(:`).exactly(2).times.and_return(1, 2)
      deploy.after :push_repo, "echo '1'"
      deploy.after :push_repo, "echo '2'"
      deploy.execute_callbacks_for(:push_repo, :after)
    end

    it 'execute command between callbacks' do
      deploy.should_receive(:`).with("echo '1'").ordered
      deploy.should_receive(:push_repo_without_callbacks).ordered
      deploy.should_receive(:`).with("echo '2'").ordered

      deploy.before :push_repo, "echo '1'"
      deploy.after :push_repo, "echo '2'"
      deploy.push_repo
    end

    it 'add callback to multiple methods' do
      deploy.should_receive(:push_repo_without_callbacks).ordered
      deploy.should_receive(:`).with("echo '1'").ordered
      deploy.should_receive(:`).with("echo '2'").ordered
      deploy.should_receive(:run_migrations_without_callbacks).ordered

      deploy.after :push_repo, "echo '1'"
      deploy.before :run_migrations, "echo '2'"
      deploy.deploy
    end

    it 'add all callbacks' do
      deploy.should_receive(:`).with("echo '1'").ordered
      deploy.should_receive(:push_repo_without_callbacks).ordered
      deploy.should_receive(:`).with("echo '2'").ordered
      deploy.should_receive(:`).with("echo '3'").ordered
      deploy.should_receive(:run_migrations_without_callbacks).ordered
      deploy.should_receive(:`).with("echo '4'").ordered

      deploy.before :push_repo, "echo '1'"
      deploy.after :push_repo, "echo '2'"
      deploy.before :run_migrations, "echo '3'"
      deploy.after :run_migrations, "echo '4'"
      deploy.deploy
    end
  end
end

