require 'spec_helper'
require 'paratrooper/http_client_wrapper'

describe Paratrooper::HttpClientWrapper do
  let(:wrapper) { described_class.new(default_options) }
  let(:default_options) do
    {
      http_client: http_client
    }
  end
  let(:http_client) { double(:http_client) }

  describe "GET a url" do
    it "accepts a string url and makes a GET request for it" do
      expected_url = "GO GET SOMETHING"
      expect(http_client).to receive(:get).with(expected_url)
      wrapper.get(expected_url)
    end
  end
end
