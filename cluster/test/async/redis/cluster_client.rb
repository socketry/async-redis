# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/redis/cluster_client'
require 'sus/fixtures/async'
require 'securerandom'

describe Async::Redis::ClusterClient do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:node_a) {"redis://redis-a:6379"}
	let(:node_b) {"redis://redis-b:6379"}
	let(:node_c) {"redis://redis-c:6379"}
	
	let(:endpoints) {[
		Async::Redis::Endpoint.parse(node_a),
		Async::Redis::Endpoint.parse(node_b),
		Async::Redis::Endpoint.parse(node_c)
	]}
	
	let(:cluster) {subject.new(endpoints)}
	
	let(:key) {"cluster-test:fixed"}
	let(:value) {"cluster-test-value"}
	
	it "can get a client for a given key" do
		slot = cluster.slot_for(key)
		client = cluster.client_for(slot)
		
		expect(client).not.to be_nil
	end
	
	it "can get and set values" do
		result = nil
		
		cluster.clients_for(key) do |client|
			client.set(key, value)
			
			result = client.get(key)
		end
		
		expect(result).to be == value
	end
end
