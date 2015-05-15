require 'spec_helper'
require 'paratrooper/configuration'

describe Paratrooper::Configuration do
  let(:configuration) { described_class.new }

  describe "attributes=" do
    it "takes hash of attributes and calls the key as a method setter" do
      attrs = { app_name: 'APP_NAME', screen_notifier: 'SCREEN_NOTIFIER' }
      configuration.attributes = attrs

      expect(configuration.app_name).to eq('APP_NAME')
      expect(configuration.screen_notifier).to eq('SCREEN_NOTIFIER')
    end
  end

  describe "app_name" do
    context "with passed value" do
      it "returns passed value" do
        configuration.app_name = "APP_NAME"
        expect(configuration.app_name).to eq("APP_NAME")
      end
    end

    context "with no value passed" do
      it "returns nil" do
        expect(configuration.app_name).to be_nil
      end
    end
  end

  describe "branch_name?" do
    context "when branch_name is a valid string" do
      it "returns true" do
        configuration.branch_name = 'BRANCH_NAME'
        expect(configuration.branch_name?).to eq(true)
      end
    end

    context "when branch_name is an invalid string" do
      it "returns false" do
        configuration.branch_name = "   "
        expect(configuration.branch_name?).to eq(false)
      end
    end

    context "when branch_name is nil" do
      it "returns false" do
        configuration.branch_name = nil
        expect(configuration.branch_name?).to eq(false)
      end
    end
  end

  describe "branch_name" do
    context "with passed value" do
      it "returns passed value" do
        configuration.branch_name = "TAG_NAME"
        expect(configuration.branch_name).to eq("TAG_NAME")
      end
    end

    context "with no value passed" do
      it "returns nil" do
        expect(configuration.branch_name).to be_nil
      end
    end
  end

  describe "protocol" do
    context "with passed value" do
      specify "passed value is returned" do
        configuration.protocol = 'https'

        expect(configuration.protocol).to eq('https')
      end
    end

    context "no value passed" do
      specify "default value of 'http' is returned" do
        expect(configuration.protocol).to eq('http')
      end
    end
  end

  describe "deployment_host" do
    context "with passed value" do
      it "returns the value passed" do
        configuration.deployment_host = 'HOST_NAME'
        expect(configuration.deployment_host).to eq('HOST_NAME')
      end
    end

    context "with no passed value" do
      it "returns the default value of 'heroku.com'" do
        expect(configuration.deployment_host).to eq('heroku.com')
      end
    end
  end

  describe "api_key" do
    context "with passed value" do
      it "returns the value passed" do
        configuration.api_key = 'API_KEY'
        expect(configuration.api_key).to eq('API_KEY')
      end
    end

    context "with no passed value" do
      it "returns nil" do
        expect(configuration.api_key).to be_nil
      end
    end
  end

  describe "maintenance" do
    context "with passed value" do
      it "returns the value passed" do
        configuration.maintenance = 'true'
        expect(configuration.maintenance).to eq(true)
      end
    end

    context "with no passed value" do
      it "returns false" do
        expect(configuration.maintenance).to eq(false)
      end
    end
  end

  describe "maintenance?" do
    context "when #maintenance is truthy" do
      it "returns true" do
        configuration.maintenance = "YUP"
        expect(configuration.maintenance?).to eq(true)
      end
    end

    context "when #maintenance is falsey" do
      it "returns false" do
        configuration.maintenance = false
        expect(configuration.maintenance?).to eq(false)
      end
    end
  end

  describe "force_push" do
    context "with passed value" do
      it "returns the value passed" do
        configuration.force_push = "true"
        expect(configuration.force_push).to eq(true)
      end
    end

    context "with no passed value" do
      it "returns false" do
        expect(configuration.force_push).to eq(false)
      end
    end
  end

  describe "#force" do
    it "writes value to #force_push" do
      configuration.force = true
      expect(configuration.force_push).to eq(true)
    end
  end

  describe "force_push?" do
    context "when #force_push is truthy" do
      it "returns true" do
        configuration.force_push = "YUP"
        expect(configuration.force_push?).to eq(true)
      end
    end

    context "when #force_push is falsey" do
      it "returns false" do
        configuration.force_push = false
        expect(configuration.force_push?).to eq(false)
      end
    end
  end

  describe "heroku" do
    context "with passed value" do
      it "returns passed value" do
        heroku = double(:heroku)
        configuration.heroku = heroku

        expect(configuration.heroku).to eq(heroku)
      end
    end

    context "with no value passed" do
      it "returns internal heroku wrapper" do
        heroku = class_double("HerokuWrapper")
        stub_const("Paratrooper::HerokuWrapper", heroku)
        wrapper_instance = double(:heroku)
        expect(heroku).to receive(:new).with("APP_NAME").and_return(wrapper_instance)

        configuration.app_name = "APP_NAME"
        expect(configuration.heroku).to eq(wrapper_instance)
      end
    end
  end

  describe "migration_check" do
    context "with passed value" do
      it "returns passed value" do
        migration_check = double(:pending_migration_check)
        configuration.migration_check = migration_check

        expect(configuration.migration_check).to eq(migration_check)
      end
    end

    context "with no value passed" do
      it "returns the default pending migration check object" do
        migration_check_class = class_double("PendingMigrationCheck")
        stub_const("Paratrooper::PendingMigrationCheck", migration_check_class)
        migration_check = double(:heroku)
        source_control = double(:source_control, deployment_sha: "SHA")

        configuration.heroku = "HEROKU"
        configuration.system_caller = "SYSTEM"
        configuration.source_control = source_control

        expect(migration_check_class).to receive(:new).with("SHA", "HEROKU", "SYSTEM")
          .and_return(migration_check)
        expect(configuration.migration_check).to eq(migration_check)
      end
    end
  end

  describe "system_caller" do
    context "with passed value" do
      it "returns passed value" do
        system_caller = double(:system_caller)
        configuration.system_caller = system_caller

        expect(configuration.system_caller).to eq(system_caller)
      end
    end

    context "with no value passed" do
      it "returns default system_caller" do
        system_caller = class_double("SystemCaller")
        stub_const("Paratrooper::SystemCaller", system_caller)
        wrapper_instance = double(:system_caller)
        expect(system_caller).to receive(:new).and_return(wrapper_instance)

        expect(configuration.system_caller).to eq(wrapper_instance)
      end
    end
  end

  describe "http_client" do
    context "with passed value" do
      it "returns passed value" do
        http_client = double(:http_client)
        configuration.http_client = http_client

        expect(configuration.http_client).to eq(http_client)
      end
    end

    context "with no value passed" do
      it "returns internal http_client wrapper" do
        http_client = class_double("HttpClientWrapper")
        stub_const("Paratrooper::HttpClientWrapper", http_client)
        wrapper_instance = double(:http_client)
        expect(http_client).to receive(:new).and_return(wrapper_instance)

        expect(configuration.http_client).to eq(wrapper_instance)
      end
    end
  end

  describe "screen_notifier" do
    context "with passed value" do
      it "returns passed value" do
        screen_notifier = double(:screen_notifier)
        configuration.screen_notifier = screen_notifier

        expect(configuration.screen_notifier).to eq(screen_notifier)
      end
    end

    context "with no value passed" do
      it "returns default screen_notifier" do
        screen_notifier = class_double("Notifiers::ScreenNotifier")
        stub_const("Paratrooper::Notifiers::ScreenNotifier", screen_notifier)
        notifier = double(:screen_notifier)
        expect(screen_notifier).to receive(:new).and_return(notifier)

        expect(configuration.screen_notifier).to eq(notifier)
      end
    end
  end

  describe "notifiers" do
    context "with passed value as array" do
      it "returns passed value" do
        notifier = double(:notifier)
        configuration.notifiers = [notifier]

        expect(configuration.notifiers).to eq([notifier])
      end
    end

    context "with passed value as single item" do
      it "returns array containing passed value" do
        notifier = double(:notifier)
        configuration.notifiers = notifier

        expect(configuration.notifiers).to eq([notifier])
      end
    end

    context "with no value passed" do
      it "returns array containing screen notifier" do
        configuration.screen_notifier = "SCREEN_NOTIFIER"

        expect(configuration.notifiers).to eq(["SCREEN_NOTIFIER"])
      end
    end
  end

  describe "source_control" do
    context "with passed value" do
      it "returns passed value" do
        source_control = double(:source_control)
        configuration.source_control = source_control

        expect(configuration.source_control).to eq(source_control)
      end
    end

    context "with no value passed" do
      it "returns default source_control" do
        source_control = class_double("SourceControl")
        stub_const("Paratrooper::SourceControl", source_control)
        controller = double(:source_control)
        expect(source_control).to receive(:new).with(configuration).and_return(controller)

        expect(configuration.source_control).to eq(controller)
      end
    end
  end

  describe "#tag=" do
    it "writes value to #tag_name" do
      configuration.tag = "TAG_NAME"
      expect(configuration.tag_name).to eq("TAG_NAME")
    end
  end

  describe "#match_tag=" do
    it "writes value to #match_tag_name" do
      configuration.match_tag = "MATCH_TAG_NAME"
      expect(configuration.match_tag_name).to eq("MATCH_TAG_NAME")
    end
  end

  describe "#branch=" do
    it "writes value to #branch_name" do
      configuration.branch = "BRANCH_NAME"
      expect(configuration.branch_name).to eq("BRANCH_NAME")
    end
  end
end
