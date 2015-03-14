begin
  require 'rspec/core/rake_task'

  desc 'Run all test specs'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task :spec do
    abort 'rspec is not available. In order to run spec, you must: gem install rspec'
  end
end

task :test => 'spec'
