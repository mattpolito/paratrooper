require 'spec_helper'
require 'paratrooper/deploy'

describe Paratrooper::Deploy do
  let(:deployer) do
    described_class.new(app_name, default_options.merge(options))
  end
  let(:app_name) { 'app' }
  let(:default_options) do
    {
      heroku: heroku,
      notifiers: [],
      system_caller: system_caller,
      migration_check: migration_check,
      screen_notifier: screen_notifier,
      http_client: http_client
    }
  end
  let(:options) { Hash.new }
  let(:heroku) do
    double(:heroku,
      app_url: 'application_url',
      app_restart: true,
      app_maintenance_on: true,
      app_maintenance_off: true,
      run_migrations: true
    )
  end
  let(:system_caller) { double(:system_caller) }
  let(:screen_notifier) { double(:screen_notifier) }
  let(:migration_check) do
    double(:migration_check, last_deployed_commit: 'DEPLOYED_SHA')
  end
  let(:domain_response) do
    double(:domain_response, body: [{'domain' => 'application_url'}])
  end
  let(:http_client) { double(:http_client).as_null_object }

  describe "tag=" do
    specify "tag is set and @tag_name holds value" do
      deployer.tag = "tag_name"
      expect(deployer.tag_name).to eq("tag_name")
    end
  end

  describe "match_tag_to=" do
    specify "match_tag is set and @match_tag_name holds value" do
      deployer.match_tag = "staging"
      expect(deployer.match_tag_name).to eq("staging")
    end
  end

  describe "branch=" do
    specify "branch is set and @branch_name holds value" do
      deployer.branch = "branch_name"
      expect(deployer.branch_name).to eq("branch_name")
    end
  end

  describe "passing a block to initialize" do
    it "sets attributes on self" do
      deployer = described_class.new(app_name, default_options) do |p|
        p.debug           = true
        p.deployment_host = "HOST"
        p.match_tag       = "staging"
        p.protocol        = "MOM"
        p.tag             = "production"
      end
      expect(deployer.match_tag_name).to eq("staging")
      expect(deployer.tag_name).to eq("production")
      expect(deployer.debug).to be(true)
      expect(deployer.deployment_host).to eq("HOST")
      expect(deployer.protocol).to eq("MOM")
    end

    it "lazy loads dependent options" do
      deployer = described_class.new(app_name, api_key: 'API_KEY') do |p|
        p.debug     = true
        p.match_tag = 'integration'
      end
      expect(deployer.system_caller.debug).to eq(true)
      expect(deployer.migration_check.match_tag_name).to eq('integration')
    end
  end

  describe "options" do
    context "accepts :tag" do
      let(:options) { { tag: 'tag_name' } }

      it "and responds to #tag_name" do
        expect(deployer.tag_name).to eq('tag_name')
      end
    end

    context "accepts :heroku_auth" do
      let(:options) { { heroku_auth: heroku } }
      let(:heroku) { double(:heroku) }

      it "and responds to #heroku" do
        expect(deployer.heroku).to eq(heroku)
      end
    end

    context "accepts :notifiers" do
      let(:options) { { notifiers: [notifiers] } }
      let(:notifiers) { double(:notifier) }

      it "and responds to #notifiers" do
        expect(deployer.notifiers).to eq([notifiers])
      end
    end

    describe "protocol" do
      context "accepts :protocol" do
        let(:options) { { protocol: 'https' } }

        it "and responds to #protocol" do
          expect(deployer.protocol).to eq('https')
        end
      end

      context "no value passed" do
        it "and responds to #protocol with default value" do
          expect(deployer.protocol).to eq('http')
        end
      end
    end

    context "accepts :deployment_host" do
      let(:options) { { deployment_host: 'host_name' } }

      it "and responds to #notifiers" do
        expect(deployer.deployment_host).to eq('host_name')
      end
    end
  end

  describe "#activate_maintenance_mode" do
    context "when maintenance option is 'true'" do
      let(:options) { { maintenance: true } }

      context "with pending migrations" do
        before do
          migration_check.stub(:migrations_waiting?).and_return(true)
        end

        it 'sends notification' do
          deployer.should_receive(:notify).with(:activate_maintenance_mode).once
          deployer.activate_maintenance_mode
        end

        it "makes call to heroku to turn on maintenance mode" do
          heroku.should_receive(:app_maintenance_on)
          deployer.activate_maintenance_mode
        end
      end

      context "without pending migrations" do
        before do
          migration_check.stub(:migrations_waiting?).and_return(false)
        end

        it 'does not send notification' do
          deployer.should_not_receive(:notify).with(:activate_maintenance_mode)
          deployer.activate_maintenance_mode
        end

        it "does not make a call to heroku to turn on maintenance mode" do
          heroku.should_not_receive(:app_maintenance_on)
          deployer.activate_maintenance_mode
        end
      end
    end

    context "when maintenance option is false" do
      let(:options) { { maintenance: false } }

      before do
        migration_check.stub(:migrations_waiting?).and_return(true)
      end

      it 'does not send notification' do
        deployer.should_not_receive(:notify).with(:activate_maintenance_mode)
        deployer.activate_maintenance_mode
      end

      it "does not make a call to heroku to turn on maintenance mode" do
        heroku.should_not_receive(:app_maintenance_on)
        deployer.activate_maintenance_mode
      end
    end

    context "when maintenance option is left as default" do
      let(:options) { { } }

      before do
        migration_check.stub(:migrations_waiting?).and_return(true)
      end

      it 'does not send notification' do
        deployer.should_not_receive(:notify).with(:activate_maintenance_mode)
        deployer.activate_maintenance_mode
      end

      it "does not make a call to heroku to turn on maintenance mode" do
        heroku.should_not_receive(:app_maintenance_on)
        deployer.activate_maintenance_mode
      end
    end
  end

  describe "#deactivate_maintenance_mode" do
    context "when maintenance_mode option is 'true'" do
      let(:options) { { maintenance_mode: true } }

      context "with pending migrations" do
        before do
          migration_check.stub(:migrations_waiting?).and_return(true)
        end

        it 'sends notification' do
          deployer.should_receive(:notify).with(:deactivate_maintenance_mode).once
          deployer.deactivate_maintenance_mode
        end

        it "makes call to heroku to turn on maintenance mode" do
          heroku.should_receive(:app_maintenance_off)
          deployer.deactivate_maintenance_mode
        end
      end

      context "without pending migrations" do
        before do
          migration_check.stub(:migrations_waiting?).and_return(false)
        end

        it 'does not send notification' do
          deployer.should_not_receive(:notify).with(:deactivate_maintenance_mode)
          deployer.deactivate_maintenance_mode
        end

        it "does not make a call to heroku to turn on maintenance mode" do
          heroku.should_not_receive(:app_maintenance_off)
          deployer.deactivate_maintenance_mode
        end
      end
    end
  end

  describe "#update_repo_tag" do
    context "when a tag_name is available" do
      let(:options) { { tag: 'awesome' } }

      before do
        system_caller.stub(:execute)
      end

      it 'sends notification' do
        deployer.should_receive(:notify).with(:update_repo_tag).once
        deployer.update_repo_tag
      end

      context "when deploy_tag is available" do
        before do
          options.merge!(match_tag: 'deploy_this')
        end

        it 'creates a git tag at deploy_tag reference point' do
          system_caller.should_receive(:execute).with('git tag awesome deploy_this -f')
          deployer.update_repo_tag
        end
      end

      context "when no deploy_tag is available" do
        it 'creates a git tag at HEAD' do
          system_caller.should_receive(:execute).with('git tag awesome master -f')
          deployer.update_repo_tag
        end
      end

      it 'pushes git tag' do
        expected = 'git push -f origin awesome'
        system_caller.should_receive(:execute).with(expected)
        deployer.update_repo_tag
      end
    end

    context "when a tag_name is unavailable" do
      let(:options) { Hash.new }

      it 'no repo tags are created' do
        system_caller.should_not_receive(:execute)
        deployer.update_repo_tag
      end
    end
  end

  describe "#push_repo" do
    before do
      system_caller.stub(:execute)
    end

    it 'sends notification' do
      deployer.should_receive(:notify)
        .with(:push_repo, reference_point: 'master', app_name: 'app', force: false).once
      deployer.push_repo
    end

    context "when branch_name is available" do
      context "and branch_name is passed as a symbol" do
        it 'pushes branch_name to heroku' do
          deployer.branch_name = :SYMBOL_BRANCH_NAME
          expected_call = 'git push git@heroku.com:app.git refs/heads/SYMBOL_BRANCH_NAME:refs/heads/master'
          system_caller.should_receive(:execute).with(expected_call)
          deployer.push_repo
        end
      end

      it 'pushes branch_name to heroku' do
        deployer.branch_name = "BRANCH_NAME"
        expected_call = 'git push git@heroku.com:app.git refs/heads/BRANCH_NAME:refs/heads/master'
        system_caller.should_receive(:execute).with(expected_call)
        deployer.push_repo
      end

      it 'supports pushing to HEAD (current branch)' do
        deployer.branch_name = :head
        expected_call = 'git push git@heroku.com:app.git HEAD:refs/heads/master'
        system_caller.should_receive(:execute).with(expected_call)
        deployer.push_repo
      end
    end

    context "when tag_name with no branch_name is available" do
      before do
        deployer.tag_name = "TAG_NAME"
      end

      it 'pushes branch_name to heroku' do
        expected_call = 'git push git@heroku.com:app.git refs/tags/TAG_NAME:refs/heads/master'
        system_caller.should_receive(:execute).with(expected_call)
        deployer.push_repo
      end
    end

    context "when no branch_name or tag_name" do
      it 'pushes master repo to heroku' do
        expected_call = 'git push git@heroku.com:app.git master:refs/heads/master'
        system_caller.should_receive(:execute).with(expected_call)
        deployer.push_repo
      end
    end

    context "when force flag is true" do
      it 'force pushes to heroku' do
        deployer.branch_name = "BRANCH_NAME"
        deployer.force = true
        expected_call = 'git push -f git@heroku.com:app.git refs/heads/BRANCH_NAME:refs/heads/master'
        system_caller.should_receive(:execute).with(expected_call)
        deployer.push_repo
      end
    end
  end

  describe "#run_migrations" do
    before do
      system_caller.stub(:execute)
    end

    context "when new migrations are waiting to be run" do
      before do
        migration_check.stub(:migrations_waiting?).and_return(true)
      end

      it 'sends notification' do
        deployer.should_receive(:notify).with(:run_migrations).once
        deployer.run_migrations
      end

      it 'pushes repo to heroku' do
        heroku.should_receive(:run_migrations)
        deployer.run_migrations
      end
    end

    context "when no migrations are available to be run" do
      before do
        migration_check.stub(:migrations_waiting?).and_return(false)
      end

      specify "heroku is not notified to run migrations" do
        heroku.should_not_receive(:run_migrations)
        deployer.run_migrations
      end
    end
  end

  describe "#app_restart" do
    context 'when a restart is required due to pending migrations' do
      before do
        migration_check.stub(:migrations_waiting?).and_return(true)
      end

      it 'sends notification' do
        expect(deployer).to receive(:notify).with(:app_restart).once
        deployer.app_restart
      end

      it 'restarts your heroku instance' do
        expect(heroku).to receive(:app_restart)
        deployer.app_restart
      end
    end

    context 'when a restart is not required' do
      before do
        migration_check.stub(:migrations_waiting?).and_return(false)
      end

      it 'does not send notification' do
        expect(deployer).to_not receive(:notify).with(:app_restart)
        deployer.app_restart
      end

      it 'does not restart your heroku instance' do
        expect(heroku).to_not receive(:app_restart)
        deployer.app_restart
      end
    end
  end

  describe "#warm_instance" do
    before do
      system_caller.stub(:execute)
    end

    it 'sends notification' do
      deployer.should_receive(:notify).with(:warm_instance).once
      deployer.warm_instance(0)
    end

    it 'pings application url' do
      expected_url = 'http://application_url'
      expect(http_client).to receive(:get).with(expected_url)
      deployer.warm_instance(0)
    end

    context 'with optional protocol' do
      let(:options) { { protocol: 'https' } }

      it 'pings application url using the protocol' do
        expected_url = 'https://application_url'
        expect(http_client).to receive(:get).with(expected_url)
        deployer.warm_instance(0)
      end
    end

    describe "#add_callback" do
      it "adds callback" do
        callback = proc do |output|
          system("touch spec/fixtures/test.txt")
        end

        deployer = described_class.new(app_name, default_options) do |p|
          p.add_callback(:before_setup, &callback)
        end

        expect(deployer.callbacks[:before_setup]).to eq([callback])
      end

      context "when messaging is added to callback" do
        it "is called" do
          callback = proc do |output|
            output.display("Whoo Hoo!")
          end

          screen_notifier.stub(:display).with("Whoo Hoo!")

          deployer = described_class.new(app_name, default_options) do |p|
            p.add_callback(:before_setup, &callback)
          end
          deployer.setup

          expect(screen_notifier).to have_received(:display).with("Whoo Hoo!")
        end
      end
    end

    describe "#add_remote_task" do
      it "makes call to heroku to run task" do
        expect(heroku).to receive(:run_task).with("rake some:task:to:run")
        deployer.add_remote_task("rake some:task:to:run")
      end
    end
  end
end
