# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/redis/client'
require 'async/redis/protocol/authenticated'
require 'sus/fixtures/async'

describe Async::Redis::Endpoint do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	
	with '#protocol' do
		it "defaults to RESP2" do
			expect(endpoint.protocol).to be == Async::Redis::Protocol::RESP2
		end
		
		with 'database selection' do
			let(:endpoint) {Async::Redis.local_endpoint(database: 1)}
			
			it "selects the database" do
				expect(endpoint.protocol).to be_a(Async::Redis::Protocol::Selected)
				expect(endpoint.protocol.index).to be == 1
			end
		end
		
		with 'credentials' do
			let(:credentials) {["testuser", "testpassword"]}
			let(:endpoint) {Async::Redis.local_endpoint(credentials: credentials)}
			
			it "authenticates with credentials" do
				expect(endpoint.protocol).to be_a(Async::Redis::Protocol::Authenticated)
				expect(endpoint.protocol.credentials).to be == credentials
			end
		end
	end
end
