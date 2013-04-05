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
      key_extractor: double(:key_extractor, get_credentials: 'API_KEY')
    }
  end
  let(:heroku_api) { double(:heroku_api) }

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
      heroku_api.should_receive(:post_ps_restart).with(app_name)
      wrapper.app_restart
    end
  end

  describe '#app_maintenance_off' do
    it "calls down to heroku api" do
      heroku_api.should_receive(:post_app_maintenance).with(app_name, '0')
      wrapper.app_maintenance_off
    end
  end

  describe '#app_maintenance_on' do
    it "calls down to heroku api" do
      heroku_api.should_receive(:post_app_maintenance).with(app_name, '1')
      wrapper.app_maintenance_on
    end
  end
  
  describe '#run_migrations' do
    it 'calls into the heroku api' do
      heroku_api.should_receive(:post_ps).with(app_name, 'rake db:migrate', attach: 'true').and_return(double(body: ''))
      Rendezvous.stub(start: nil)
      wrapper.run_migrations
    end
    
    it 'uses waits for db migrations to run using rendezvous' do
      data = { 'rendezvous_url' => 'the_url' }
      heroku_api.stub_chain(:post_ps, :body).and_return(data)
      Rendezvous.should_receive(:start).with(:url => data['rendezvous_url'])
      wrapper.run_migrations
    end
  end

  describe '#app_url' do
    context 'when custom domains are available' do
      let(:response) { double(:response, body: [{'domain' => 'APP_URL'}]) }

      it "calls down to heroku api" do
        heroku_api.should_receive(:get_domains).with(app_name).and_return(response)
        wrapper.app_url
      end
    end

    context 'when custom urls are not available' do
      let(:response) do
        double(:response, body: { 'domain_name' => { 'domain' => 'APP_URL' } })
      end

      let(:domain_response) do
        double(:domain_response, body: [])
      end

      before do
        heroku_api.stub(:get_domains).and_return(domain_response)
      end

      it "makes call to get default heroku app url" do
        heroku_api.should_receive(:get_app).with(app_name).and_return(response)
        expect(wrapper.app_url).to eq('APP_URL')
      end
    end
  end
end
