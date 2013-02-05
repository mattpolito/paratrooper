require 'rspec'

def fixture_path(file)
  File.expand_path("../fixtures/#{file}", __FILE__)
end
