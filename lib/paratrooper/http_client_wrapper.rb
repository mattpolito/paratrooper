module Paratrooper
  class HttpClientWrapper
    attr_reader :http_client

    def initialize(options = {})
      @http_client= options[:http_client] || Excon
    end

    def get(url)
      http_client.get(url)
    end
  end
end
