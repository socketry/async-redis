# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/redis/cluster_client'
require 'sus/fixtures/async'
require 'securerandom'

describe Async::Redis::ClusterClient do
	let(:client) {subject.new([])}
	
	with "#slot_for" do
		it "can compute the correct slot for a given key" do
			expect(client.slot_for("helloworld")).to be == 2739
			expect(client.slot_for("test1234")).to be == 15785
		end
	end
end
