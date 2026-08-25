# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "async/redis/cluster_client"
require "sus/fixtures/async"
require "securerandom"

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
	let(:shards) do
		client = Async::Redis::Client.new(endpoints.first)
		
		begin
			client.call("CLUSTER", "SHARDS")
		ensure
			client.close
		end
	end
	
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
	
	it "can map every slot to a client" do
		clients = Async::Redis::ClusterClient::HASH_SLOTS.times.map do |slot|
			client = cluster.client_for(slot)
		end.uniq
		
		expect(clients.size).to be == 3
		expect(clients).not.to have_value(be_nil)
	end
	
	it "can map multiple slot ranges for one shard" do
		slots = shards.filter_map do |shard|
			shard = shard.each_slice(2).to_h
			shard["slots"] if shard["slots"].size > 2
		end.first
		
		expect(slots).not.to be_nil
		
		clients = slots.each_slice(2).flat_map do |first_slot, last_slot|
			[cluster.client_for(first_slot), cluster.client_for(last_slot)]
		end.uniq
		
		expect(clients.size).to be == 1
	end
end
