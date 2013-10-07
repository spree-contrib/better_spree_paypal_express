require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rubygems/package_task'
require 'rspec/core/rake_task'
require 'spree/testing_support/extension_rake'

desc 'Generates a dummy app for testing'
task :test_app do
  ENV['LIB_NAME'] = 'spree_paypal_express'
  Rake::Task['extension:test_app'].invoke
end

require 'rspec/core'
require 'rspec/core/rake_task'
Rake::Task["spec"].clear
RSpec::Core::RakeTask.new(:spec) do |t|
  t.fail_on_error = false
  t.rspec_opts = %w[-f JUnit -o results.xml]
end

desc "Run RSpec with code coverage"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task["spec"].execute
end
task :default => :spec


Bundler::GemHelper.install_tasks
