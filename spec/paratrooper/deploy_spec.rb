require 'spec_helper'
require 'paratrooper/deploy'

describe Paratrooper::Deploy do
  let(:deployer) do
    described_class.new(app_name, default_options.merge(options))
  end
  let(:app_name) { 'app' }
  let(:default_options) do
    {
      heroku_auth: heroku,
      formatter: formatter,
      system_caller: system_caller
    }
  end
  let(:options) { Hash.new }
  let(:heroku) do
    double(:heroku,
      post_app_maintenance: true,
      post_ps_restart: true,
      get_domains: domain_response
    )
  end
  let(:formatter) { double(:formatter, puts: '') }
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

    context "accepts :formatter" do
      let(:options) { { formatter: formatter } }
      let(:formatter) { double(:formatter) }

      it "and responds to #formatter" do
        expect(deployer.formatter).to eq(formatter)
      end
    end
  end

  describe "#activate_maintenance_mode" do
    let(:options) { { formatter: formatter } }
    let(:formatter) { double(:formatter, puts: true) }

    it "displays message" do
      formatter.should_receive(:puts).with('Activating Maintenance Mode')
      deployer.activate_maintenance_mode
    end

    it "makes call to heroku to turn on maintenance mode" do
      heroku.should_receive(:post_app_maintenance).with(app_name, '1')
      deployer.activate_maintenance_mode
    end
  end

  describe "#deactivate_maintenance_mode" do
    it "displays message" do
      formatter.should_receive(:puts).with('Deactivating Maintenance Mode')
      deployer.deactivate_maintenance_mode
    end

    it "makes call to heroku to turn on maintenance mode" do
      heroku.should_receive(:post_app_maintenance).with(app_name, '0')
      deployer.deactivate_maintenance_mode
    end
  end

  describe "#update_repo_tag" do
    context "when a tag_name is available" do
      let(:options) { { tag: 'awesome' } }

      before do
        system_caller.stub(:execute)
      end

      it 'displays message' do
        formatter.should_receive(:puts).with('Updating Repo Tag: awesome')
        deployer.update_repo_tag
      end

      it 'creates a git tag' do
        system_caller.should_receive(:execute).with('git tag awesome -f')
        deployer.update_repo_tag
      end

      it 'pushes git tag' do
        system_caller.should_receive(:execute).with('git push origin awesome')
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

    it 'displays message' do
      formatter.should_receive(:puts).with('Pushing master to Heroku')
      deployer.push_repo
    end

    it 'pushes repo to heroku' do
      expected_call = 'git push -f git@heroku.com:app.git master'
      system_caller.should_receive(:execute).with(expected_call)
      deployer.push_repo
    end
  end

  describe "#run_migrations" do
    before do
      system_caller.stub(:execute)
    end

    it 'displays message' do
      formatter.should_receive(:puts).with('Running database migrations')
      deployer.run_migrations
    end

    it 'pushes repo to heroku' do
      expected_call = 'heroku run rake db:migrate --app app'
      system_caller.should_receive(:execute).with(expected_call)
      deployer.run_migrations
    end
  end

  describe "#app_restart" do
    it 'displays message' do
      formatter.should_receive(:puts).with('Restarting application')
      deployer.app_restart
    end

    it 'restarts your heroku instance' do
      heroku.should_receive(:post_ps_restart).with(app_name)
      deployer.app_restart
    end
  end

  describe "#warm_instance" do
    before do
      system_caller.stub(:execute)
    end

    it 'displays message' do
      expected_notice = 'Accessing application_url to warm up your application'
      formatter.should_receive(:puts).with(expected_notice)
      deployer.warm_instance(0)
    end

    it 'pings application url' do
      expected_call = 'curl -Il http://application_url'
      system_caller.should_receive(:execute).with(expected_call)
      deployer.warm_instance(0)
    end
  end
end
