require 'spec_helper'
require 'fileutils'
require 'paratrooper/local_api_key_extractor'

describe Paratrooper::LocalApiKeyExtractor do
  let(:netrc_klass) { double(:netrc_klass, default_path: fixture_file_path) }
  let(:fixture_file_path) { fixture_path('netrc') }

  describe 'file association' do
    before do
      File.chmod(0600, fixture_file_path)
    end

    context 'when file path is provided' do
      let(:extractor) { described_class.new(file_path: fixture_file_path) }

      it 'uses provided file path' do
        expect(extractor.file_path).to eq(fixture_file_path)
      end
    end

    context 'when file path is not provided' do
      let(:extractor) { described_class.new(netrc_klass: netrc_klass) }

      it 'uses default path' do
        expect(extractor.file_path).to eq(netrc_klass.default_path)
      end
    end
  end

  describe '#read_credentials' do
    let(:extractor) { described_class.new(netrc_klass: netrc_klass) }

    context 'when environment variable is set' do
      before do
        ENV.stub(:[]).with('HEROKU_API_KEY').and_return('ENV_API_KEY')
      end

      it 'returns credentials' do
        expect(extractor.read_credentials).to eq('ENV_API_KEY')
      end
    end

    context 'when environment variable is not set' do
      before do
        ENV.stub(:[])
        ENV.stub(:[]).with('HEROKU_API_KEY').and_return(nil)
      end

      it 'returns credentials from local file' do
        expect(extractor.read_credentials).to eq('LOCAL_API_KEY')
      end

      context 'and no local file is available' do
        let(:fixture_file_path) { fixture_path('no_netrc') }

        it 'throws error' do
          expect{ extractor.read_credentials }.to raise_error(described_class::NetrcFileDoesNotExist, /#{fixture_file_path}/)
        end
      end
    end
  end
end
