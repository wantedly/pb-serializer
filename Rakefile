require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :generate do
  system "protoc --ruby_out=. ./spec/fixtures/*.proto"
end
