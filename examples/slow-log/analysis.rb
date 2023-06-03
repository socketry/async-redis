#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require 'set'
require 'async'
require_relative '../../lib/async/redis'

endpoint = Async::Redis.local_endpoint(port: 6380)
client = Async::Redis::Client.new(endpoint)

IGNORE = Set["evalsha", "lpush"]

Async do
	results = client.call("SLOWLOG", "GET", 10_000)
	
	histogram = Hash.new{|h,k| h[k] = 0}
	timestamps = []
	count = 0
	
	results.each do |event|
		count += 1
		
		id, timestamp, duration, command, host, client, name = *event
		
		# next if IGNORE.include?(command.first.downcase)
		
		# Duration in milliseconds:
		duration = duration / 1_000.0
		
		# Time from timestamp:
		timestamp = Time.at(timestamp, in: 0)
		
		# if command.first.downcase == "keys" && command[1] =~ /active-test/
		# 	timestamps << timestamp
		# end
		
		histogram[command.first] += duration
	end
	
	pp histogram
	# pp timestamps.sort
end
