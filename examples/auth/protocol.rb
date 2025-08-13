# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "../../lib/async/redis"

class AuthenticatedRESP2
	def initialize(credentials, protocol: Async::Redis::Protocol::RESP2)
		@credentials = credentials
		@protocol = protocol
	end
	
	def client(stream)
		client = @protocol.client(stream)
		
		client.write_request(["AUTH", *@credentials])
		client.read_response # Ignore response.
		
		return client
	end
end

Async do
	endpoint = Async::Redis.local_endpoint
	
	client = Async::Redis::Client.new(endpoint, protocol: AuthenticatedRESP2.new(["username", "password"]))
	
	pp client.info
end
