# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2019, by David Ortiz.

require "client_context"

describe Protocol::Redis::Methods::Lists do
	include_context ClientContext
	
	let(:list_a) {root["list_a"]}
	let(:list_b) {root["list_b"]}
	let(:test_list) {(0..4).to_a}
	
	it "can do non blocking push/pop operations" do
		expect(client.lpush list_a, test_list).to be == test_list.length
		expect(client.rpush list_b, test_list).to be == test_list.length
		
		expect(client.llen list_a).to be == client.llen(list_b)
		
		test_list.each do |i|
			item_a = client.lpop list_a
			item_b = client.rpop list_b
			expect(item_a).to be == item_b
		end
	end

	it "can conditionally push and pop items from lists" do
		
	end

	it "can get, set and remove values at specific list indexes" do
		
	end
	
	it "can get a list slice" do
		client.rpush(list_a, test_list)
		
		slice_size = list_a.size/2
		
		expect(client.lrange(list_a, 0, slice_size - 1)).to be == test_list.take(slice_size).map(&:to_s)
	end
	
	it "can trim lists" do
		
	end
end
