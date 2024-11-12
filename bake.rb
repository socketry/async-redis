# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

def client
	require "irb"
	require "async/redis/client"
	
	endpoint = Async::Redis.local_endpoint
	client = Async::Redis::Client.new(endpoint)
	
	Async do
		binding.irb
	end
end
