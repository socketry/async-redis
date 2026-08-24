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
	
	with "#slot_ranges_for" do
		it "parses a single slot range" do
			ranges = client.send(:slot_ranges_for, [0, 5460])
			
			expect(ranges).to be == [0..5460]
		end
		
		it "parses multiple slot ranges from one shard" do
			ranges = client.send(:slot_ranges_for, [0, 5460, 10923, 16383])
			
			expect(ranges).to be == [0..5460, 10923..16383]
		end
		
		it "handles nil slots gracefully" do
			ranges = client.send(:slot_ranges_for, nil)
			
			expect(ranges).to be == []
		end
		
		it "handles an empty array" do
			ranges = client.send(:slot_ranges_for, [])
			
			expect(ranges).to be == []
		end
		
		it "discards a trailing unpaired slot value" do
			ranges = client.send(:slot_ranges_for, [0, 5460, 10923])
			
			expect(ranges).to be == [0..5460]
		end
		
		it "coerces string values to integers" do
			ranges = client.send(:slot_ranges_for, ["0", "5460"])
			
			expect(ranges).to be == [0..5460]
		end
	end
end
