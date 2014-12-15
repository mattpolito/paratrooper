require 'paratrooper/version'
require 'paratrooper/deploy'

module Paratrooper
  def self.deploy(app_name, options = {}, &block)
    Deploy.call(app_name, options, &block)
  end
end
