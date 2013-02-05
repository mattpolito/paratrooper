require 'netrc'

module Paratrooper
  class LocalApiKeyExtractor
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
      @netrc ||= begin
        File.exists?(file_path) && Netrc.read(file_path)
      rescue => error
        raise error
      end
    end

    def read_credentials_for(domain)
      netrc[domain][1]
    end
  end
end
