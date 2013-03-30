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
      callbacks: [],
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
    
    context "accepts :callbacks" do
      let(:options) { { callbacks: [callbacks] } }
      let(:callbacks) { double(:callback) }

      it "and responds to #callbacks" do
        expect(deployer.callbacks).to eq([callbacks])
      end
    end
  end
  
  describe '#before' do
    context 'when a callback returns false' do
      let(:options) { { callbacks: [callback] } }
      let(:callback) { double(:callback, run: false) }
      
      it 'does not yield to the block' do
        expect{|b| deployer.before(:something, &b)}.not_to yield_control
      end
    end
    
    context 'when no callback returns false' do
      let(:options) { { callbacks: [callback] } }
      let(:callback) { double(:callback, run: true) }
      
      it 'yields to the block' do
        expect{|b| deployer.before(:something, &b)}.to yield_control
      end
    end
  end

  describe "#activate_maintenance_mode" do
    it 'runs before callbacks' do
      deployer.should_receive(:before).with(:activate_maintenance_mode).once
      deployer.activate_maintenance_mode
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

  describe "#deactivate_maintenance_mode" do
    it 'runs before callbacks' do
      deployer.should_receive(:before).with(:deactivate_maintenance_mode).once
      deployer.deactivate_maintenance_mode
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
        
        it 'runs before callbacks' do
          deployer.should_receive(:before).with(:update_repo_tag).once
          deployer.update_repo_tag
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
      
      it 'doesn\'t run before callbacks' do
        deployer.should_not_receive(:before).with(:update_repo_tag)
        deployer.update_repo_tag
      end
    end
  end

  describe "#push_repo" do
    before do
      system_caller.stub(:execute)
    end
    
    it 'runs before callbacks' do
      deployer.should_receive(:before).with(:push_repo, reference_point: 'master').once
      deployer.push_repo
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

    it 'runs before callbacks' do
      deployer.should_receive(:before).with(:run_migrations).once
      deployer.run_migrations
    end
    
    it 'sends notification' do
      deployer.should_receive(:notify).with(:run_migrations).once
      deployer.run_migrations
    end

    it 'pushes repo to heroku' do
      expected_call = 'heroku run rake db:migrate --app app'
      system_caller.should_receive(:execute).with(expected_call)
      deployer.run_migrations
    end
  end

  describe "#app_restart" do
    it 'runs before callbacks' do
      deployer.should_receive(:before).with(:app_restart).once
      deployer.app_restart
    end
    
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

    it 'runs before callbacks' do
      deployer.should_receive(:before).with(:warm_instance).once
      deployer.warm_instance
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
  end
end
