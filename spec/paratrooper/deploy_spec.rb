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

  before do
    allow(screen_notifier).to receive(:notify)
  end

  describe "passing a block to initialize" do
    it "sets attributes on self" do
      deployer = described_class.new(app_name, default_options) do |p|
        p.deployment_host = "HOST"
        p.protocol        = "MOM"
      end
      expect(deployer.config.deployment_host).to eq("HOST")
      expect(deployer.config.protocol).to eq("MOM")
    end

    it "lazy loads dependent options" do
      deployer = described_class.new(app_name, api_key: 'API_KEY') do |p|
        p.force_push = false
      end
      expect(deployer.config.api_key).to eq('API_KEY')
      expect(deployer.config.force_push).to eq(false)
    end
  end

  describe "#activate_maintenance_mode" do
    context "when maintenance option is 'true'" do
      let(:options) { { maintenance: true } }

      context "with pending migrations" do
        before do
          allow(migration_check).to receive(:migrations_waiting?).and_return(true)
        end

        it 'sends notification' do
          expect(deployer).to receive(:notify).with(:activate_maintenance_mode).once
          deployer.activate_maintenance_mode
        end

        it "makes call to heroku to turn on maintenance mode" do
          expect(heroku).to receive(:app_maintenance_on)
          deployer.activate_maintenance_mode
        end
      end

      context "without pending migrations" do
        before do
          allow(migration_check).to receive(:migrations_waiting?).and_return(false)
        end

        it 'does not send notification' do
          expect(deployer).to_not receive(:notify).with(:activate_maintenance_mode)
          deployer.activate_maintenance_mode
        end

        it "does not make a call to heroku to turn on maintenance mode" do
          expect(heroku).to_not receive(:app_maintenance_on)
          deployer.activate_maintenance_mode
        end
      end
    end

    context "when maintenance option is false" do
      let(:options) { { maintenance: false } }

      before do
        allow(migration_check).to receive(:migrations_waiting?).and_return(true)
      end

      it 'does not send notification' do
        expect(deployer).to_not receive(:notify).with(:activate_maintenance_mode)
        deployer.activate_maintenance_mode
      end

      it "does not make a call to heroku to turn on maintenance mode" do
        expect(heroku).to_not receive(:app_maintenance_on)
        deployer.activate_maintenance_mode
      end
    end

    context "when maintenance option is left as default" do
      let(:options) { { } }

      before do
        allow(migration_check).to receive(:migrations_waiting?).and_return(true)
      end

      it 'does not send notification' do
        expect(deployer).to_not receive(:notify).with(:activate_maintenance_mode)
        deployer.activate_maintenance_mode
      end

      it "does not make a call to heroku to turn on maintenance mode" do
        expect(heroku).to_not receive(:app_maintenance_on)
        deployer.activate_maintenance_mode
      end
    end
  end

  describe "#deactivate_maintenance_mode" do
    context "when maintenance_mode option is 'true'" do
      let(:options) { { maintenance: true } }

      context "with pending migrations" do
        before do
          allow(migration_check).to receive(:migrations_waiting?).and_return(true)
        end

        it 'sends notification' do
          expect(deployer).to receive(:notify).with(:deactivate_maintenance_mode).once
          deployer.deactivate_maintenance_mode
        end

        it "makes call to heroku to turn on maintenance mode" do
          expect(heroku).to receive(:app_maintenance_off)
          deployer.deactivate_maintenance_mode
        end
      end

      context "without pending migrations" do
        before do
          allow(migration_check).to receive(:migrations_waiting?).and_return(false)
        end

        it 'does not send notification' do
          expect(deployer).to_not receive(:notify).with(:deactivate_maintenance_mode)
          deployer.deactivate_maintenance_mode
        end

        it "does not make a call to heroku to turn on maintenance mode" do
          expect(heroku).to_not receive(:app_maintenance_off)
          deployer.deactivate_maintenance_mode
        end
      end
    end
  end

  describe "#push_repo" do
    let(:notifier) { double(:notifier) }
    let(:source_control) { double(:source_control) }
    let(:deployer) do
      described_class.new('APP') do |d|
        d.notifiers = notifier
        d.source_control = source_control
      end
    end

    before do
      allow(source_control).to receive(:reference_point)
      allow(source_control).to receive(:remote)
      allow(source_control).to receive(:push_to_deploy)
      allow(notifier).to receive(:notify)
    end

    it "sends notification" do
      allow(notifier).to receive(:notify) do |step, options|
        expect(step).to eq(:push_repo)
      end
      deployer.push_repo

      expect(notifier).to have_received(:notify).once
    end

    it "pushes repo to remote" do
      deployer.push_repo

      expect(source_control).to have_received(:push_to_deploy)
    end
  end

  describe "#run_migrations" do
    before do
      allow(system_caller).to receive(:execute)
    end

    context "when new migrations are waiting to be run" do
      before do
        allow(migration_check).to receive(:migrations_waiting?).and_return(true)
      end

      it 'sends notification' do
        expect(deployer).to receive(:notify).with(:run_migrations).once
        deployer.run_migrations
      end

      it 'pushes repo to heroku' do
        expect(heroku).to receive(:run_migrations)
        deployer.run_migrations
      end
    end

    context "when no migrations are available to be run" do
      before do
        allow(migration_check).to receive(:migrations_waiting?).and_return(false)
      end

      specify "heroku is not notified to run migrations" do
        expect(heroku).to_not receive(:run_migrations)
        deployer.run_migrations
      end
    end
  end
  
  describe "#precompile_assets" do
    before do
      system_caller.stub(:execute)
    end

    it 'sends notification' do
      deployer.should_receive(:notify).with(:precompile_assets).once
      deployer.precompile_assets
    end

    it 'precompiles assets' do
      expected_call = 'heroku run rake assets:precompile --app app'
      system_caller.should_receive(:execute).with(expected_call)
      deployer.precompile_assets
    end
  end

  describe "#app_restart" do
    context 'when a restart is required due to pending migrations' do
      before do
        allow(migration_check).to receive(:migrations_waiting?).and_return(true)
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
        allow(migration_check).to receive(:migrations_waiting?).and_return(false)
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

  describe "#add_callback" do
    it "adds callback" do
      callback = proc do |output|
        system("touch spec/fixtures/test.txt")
      end

      deployer = described_class.new(app_name, default_options) do |p|
        p.add_callback(:before_setup, &callback)
      end

      expect(deployer.config.callbacks[:before_setup]).to eq([callback])
    end

    context "when messaging is added to callback" do
      it "is called" do
        callback = proc do |output|
          output.display("Whoo Hoo!")
        end

        allow(screen_notifier).to receive(:display).with("Whoo Hoo!")

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
