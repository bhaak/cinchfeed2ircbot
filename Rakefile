#!/usr/bin/env rake

require 'rubygems'
require "bundler/setup"

load File.expand_path('lib/tasks/spec.rake')

desc 'run cinchfeed2ircbot'
task :run do
  load './cinchfeed2ircbot.rb'
end

task :default => :run
