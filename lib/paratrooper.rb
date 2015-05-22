require 'paratrooper/version'
require 'paratrooper/deploy'

module Paratrooper
  def self.deploy(app_name, options = {}, &block)
    Deploy.call(app_name, options, &block)
  end

  def self.deployed_slug(app_name)
    Deploy.new(nil).deployed_slug(app_name)
  end
end
