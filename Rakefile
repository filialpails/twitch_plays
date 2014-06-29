require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new

desc 'Run all specs with simplecov'
task :cov do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:spec].invoke
end

YARD::Rake::YardocTask.new

task :default => :spec
