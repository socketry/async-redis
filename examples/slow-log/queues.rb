#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require "async"
require_relative "../../lib/async/redis"

endpoint = Async::Redis.local_endpoint(port: 6380)
client = Async::Redis::Client.new(endpoint)

Async do
	pipeline = client.pipeline
	pipeline.call("SELECT", 7)
	
	queues = pipeline.sync.keys("queue:*")
	
	queues.each do |queue_key|
		length = pipeline.sync.llen(queue_key)
		
		if length > 0
			puts "#{queue_key} -> #{length} items"
			
			items = pipeline.sync.lrange(queue_key, 0, -1)
			items.each_with_index do |item, index|
				puts "\tItem #{index}: #{item.bytesize}b" if item.bytesize > 1024
			end
		end
	rescue
		puts "Could not inspect queue: #{queue_key}"
	end
end
