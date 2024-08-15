# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/redis/client'
require 'async/redis/protocol/authenticated'
require 'sus/fixtures/async'

describe Async::Redis::Protocol::Authenticated do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:credentials) {["testuser", "testpassword"]}
	let(:protocol) {subject.new(credentials)}
	let(:client) {Async::Redis::Client.new(endpoint, protocol: protocol)}
	
	before do
		# Setup ACL user with limited permissions for testing.
		admin_client = Async::Redis::Client.new(endpoint)
		admin_client.call("ACL", "SETUSER", "testuser", "on", ">" + credentials[1], "+ping", "+auth")
	ensure
		admin_client.close
	end
	
	after do
		# Cleanup ACL user after tests.
		admin_client = Async::Redis::Client.new(endpoint)
		admin_client.call("ACL", "DELUSER", "testuser")
		admin_client.close
	end
	
	it "can authenticate and send allowed commands" do
		response = client.call("PING")
		expect(response).to be == "PONG"
	end
	
	it "rejects commands not allowed by ACL" do
		expect do
			client.call("SET", "key", "value")
		end.to raise_exception(Protocol::Redis::ServerError, message: be =~ /NOPERM/)
	end
end
