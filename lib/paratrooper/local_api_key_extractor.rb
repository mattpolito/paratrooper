require 'netrc'

module Paratrooper
  class LocalApiKeyExtractor
    class NetrcFileDoesNotExist < StandardError; end

    attr_reader :file_path, :netrc_klass

    def self.get_credentials
      new.read_credentials
    end

    def initialize(options = {})
      @netrc_klass = options[:netrc_klass] || Netrc
      @file_path   = options[:file_path] || netrc_klass.default_path
    end

    def read_credentials
      ENV['HEROKU_API_KEY'] || read_credentials_for('api.heroku.com')
    end

    private
    def netrc
      unless netrc_present?
        raise NetrcFileDoesNotExist, netrc_file_missing_message
      end
      @netrc ||= Netrc.read(file_path)
    end

    def read_credentials_for(domain)
      netrc[domain][1]
    end

    def netrc_file_missing_message
      "Unable to find netrc file. Expected location: #{netrc_klass.default_path}."
    end

    def netrc_present?
      File.exists?(file_path)
    end
  end
end
