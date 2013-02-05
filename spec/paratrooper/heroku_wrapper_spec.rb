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
      heroku_api: heroku_api
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

  describe '#app_domain_name' do
    let(:response) { double(:response, body: [{'domain' => 'APP_URL'}]) }
    it "calls down to heroku api" do
      heroku_api.should_receive(:get_domains).with(app_name).and_return(response)
      wrapper.app_url
    end
  end
end
