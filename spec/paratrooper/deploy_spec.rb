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
      system_caller: system_caller
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
  let(:domain_response) do
    double(:domain_response, body: [{'domain' => 'application_url'}])
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

    context "accepts :protocol" do
      let(:options) { { protocol: 'https' } }

      it "and responds to #notifiers" do
        expect(deployer.protocol).to eq('https')
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
    it 'sends notification' do
      deployer.should_receive(:notify).with(:activate_maintenance_mode).once
      deployer.activate_maintenance_mode
    end

    it "makes call to heroku to turn on maintenance mode" do
      heroku.should_receive(:app_maintenance_on)
      deployer.activate_maintenance_mode
    end
  end

  describe "#deactivate_maintenance_mode" do
    it 'sends notification' do
      deployer.should_receive(:notify).with(:deactivate_maintenance_mode).once
      deployer.deactivate_maintenance_mode
    end

    it "makes call to heroku to turn on maintenance mode" do
      heroku.should_receive(:app_maintenance_off)
      deployer.deactivate_maintenance_mode
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
          options.merge!(match_tag_to: 'deploy_this')
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
        system_caller.should_receive(:execute).with('git push -f git@heroku.com:app.git awesome')
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
        .with(:push_repo, reference_point: 'master').once
      deployer.push_repo
    end

    it 'pushes repo to heroku' do
      expected_call = 'git push -f git@heroku.com:app.git master:master'
      system_caller.should_receive(:execute).with(expected_call)
      deployer.push_repo
    end
  end

  describe "#run_migrations" do
    before do
      system_caller.stub(:execute)
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

  describe "#app_restart" do
    it 'sends notification' do
      deployer.should_receive(:notify).with(:app_restart).once
      deployer.app_restart
    end

    it 'restarts your heroku instance' do
      heroku.should_receive(:app_restart)
      deployer.app_restart
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
      expected_call = 'curl -Il http://application_url'
      system_caller.should_receive(:execute).with(expected_call)
      deployer.warm_instance(0)
    end

    context 'with optional protocol' do
      let(:options) { { protocol: 'https' } }

      it 'pings application url using the protocol' do
        expected_call = 'curl -Il https://application_url'
        system_caller.should_receive(:execute).with(expected_call)
        deployer.warm_instance(0)
      end
    end
  end
end
