# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "async/redis/cluster_client"
require "sus/fixtures/async"
require "securerandom"

describe Async::Redis::ClusterClient do
	let(:client) {subject.new([])}
	
	with "#slot_for" do
		it "can compute the correct slot for a given key" do
			expect(client.slot_for("helloworld")).to be == 2739
			expect(client.slot_for("test1234")).to be == 15785
		end
	end
	
	with "#any_client" do
		it "samples shard nodes rather than slot ranges" do
			expected_node = Async::Redis::ClusterClient::Node.new("shard", nil, :master, :online, :expected_client)
			unexpected_node = Async::Redis::ClusterClient::Node.new("range", nil, :master, :online, :unexpected_client)
			
			shards = Async::Redis::RangeMap.new
			shards.add(0..8191, [unexpected_node])
			shards.add(8192..16_383, [unexpected_node])
			
			client.instance_variable_set(:@shards, shards)
			client.instance_variable_set(:@shard_nodes, [[expected_node]])
			
			expect(client.any_client).to be == :expected_client
		end
	end
end
