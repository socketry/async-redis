# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

task :default => :test

task :client do
	require 'irb'
	require 'async/redis/client'
	
	endpoint = Async::Redis.local_endpoint
	client = Async::Redis::Client.new(endpoint)
	
	Async do
		binding.irb
	end
end
