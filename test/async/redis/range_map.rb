# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/redis/range_map"

describe Async::Redis::RangeMap do
	let(:map) {subject.new}
	
	it "can associate multiple ranges with one value" do
		map.add([0..5, 10..15], :first)
		map.add(6..9, :second)
		
		expect(map.find(0)).to be == :first
		expect(map.find(12)).to be == :first
		expect(map.find(7)).to be == :second
	end
	
	it "treats grouped ranges as one mapping" do
		map.add([0..5, 10..15], :first)
		
		values = []
		map.each{|value| values << value}
		
		expect(values).to be == [:first]
		expect(map.sample).to be == :first
	end
end
