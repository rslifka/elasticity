require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

desc 'Run specs'
task :default => :spec
