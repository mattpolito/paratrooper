require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts ||= []
  t.rspec_opts << '--format progress'
end

task :default => :spec
