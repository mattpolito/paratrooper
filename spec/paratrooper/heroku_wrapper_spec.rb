require 'spec_helper'
require 'paratrooper/heroku_wrapper'

describe Paratrooper::HerokuWrapper do
  let(:wrapper) do
    described_class.new(app_name, default_options.merge(options))
  end
  let(:app_name) { 'app_name' }
  let(:options) { Hash.new }
  let(:default_options) do
    {
      heroku_api: heroku_api,
      key_extractor: double(:key_extractor, get_credentials: 'API_KEY'),
      rendezvous: rendezvous
    }
  end
  let(:heroku_api) { double(:heroku_api) }
  let(:rendezvous) { double(:rendezvous, start: nil) }

  describe '#api_key' do
    context 'when api_key is provided as an option' do
      let(:options) do
        {
          api_key: 'PROVIDED_API_KEY'
        }
      end

      it 'returns provided api key' do
        expect(wrapper.api_key).to eq('PROVIDED_API_KEY')
      end
    end

    context 'when no key is provided' do
      let(:options) do
        {
          key_extractor: double(:key_extractor, get_credentials: 'NETRC_API_KEY')
        }
      end

      it 'returns api key from locally stored file' do
        expect(wrapper.api_key).to eq('NETRC_API_KEY')
      end
    end
  end

  describe '#app_restart' do
    it "calls down to heroku api" do
      expect(heroku_api).to receive(:post_ps_restart).with(app_name)
      wrapper.app_restart
    end
  end

  describe '#app_maintenance_off' do
    it "calls down to heroku api" do
      expect(heroku_api).to receive(:post_app_maintenance).with(app_name, '0')
      wrapper.app_maintenance_off
    end
  end

  describe '#app_maintenance_on' do
    it "calls down to heroku api" do
      expect(heroku_api).to receive(:post_app_maintenance).with(app_name, '1')
      wrapper.app_maintenance_on
    end
  end

  describe '#run_migrations' do
    it 'calls into the heroku api' do
      expect(heroku_api).to receive(:post_ps).with(app_name, 'rake db:migrate', attach: 'true').and_return(double(body: ''))
      wrapper.run_migrations
    end

    it 'uses waits for db migrations to run using rendezvous' do
      data = { 'rendezvous_url' => 'the_url' }
      allow(heroku_api).to receive_message_chain(:post_ps, :body).and_return(data)
      expect(rendezvous).to receive(:start).with(:url => data['rendezvous_url'])
      wrapper.run_migrations
    end
  end

  describe "#last_deployed_commit" do
    context "when deploy data is returned" do
      let(:response) do
        double(:response, body: [{ 'commit' => 'SHA' }])
      end
      it "returns string of last deployed commit" do
        expect(heroku_api).to receive(:get_releases).with(app_name)
          .and_return(response)
        expect(wrapper.last_deployed_commit).to eq('SHA')
      end
    end

    context "when no deploys have happened yet" do
      let(:response) do
        double(:response, body: [])
      end

      it "returns nil" do
        expect(heroku_api).to receive(:get_releases).with(app_name)
          .and_return(response)
        expect(wrapper.last_deployed_commit).to eq(nil)
      end
    end
  end

  describe "#run_task" do
    it 'calls into the heroku api' do
      task = 'rake some:task:to:run'
      expect(heroku_api).to receive(:post_ps).with(app_name, task, attach: 'true').and_return(double(body: ''))
      wrapper.run_task(task)
    end
  end
end
