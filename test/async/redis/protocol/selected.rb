# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "async/redis/client"
require "async/redis/protocol/selected"
require "sus/fixtures/async"

describe Async::Redis::Protocol::Selected do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:index) {1}
	let(:protocol) {subject.new(index)}
	let(:client) {Async::Redis::Client.new(endpoint, protocol: protocol)}
	
	it "can select a specific database" do
		response = client.client_info
		expect(response[:db].to_i).to be == index
	end
end
