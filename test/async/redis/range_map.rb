# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/redis/range_map"

describe Async::Redis::RangeMap do
	let(:map) {subject.new}
	
	with "#add and #find" do
		it "can associate a single range with a value" do
			expect(map.add(0..5, :value)).to be == :value
			expect(map.find(3)).to be == :value
		end
		
		it "can associate multiple ranges with one value" do
			map.add([0..5, 10..15], :value)
			
			expect(map.find(0)).to be == :value
			expect(map.find(12)).to be == :value
			expect(map.find(7)).to be_nil
		end
		
		it "can provide a fallback for missing keys" do
			expect(map.find(5)).to be_nil
			expect(map.find(5){:missing}).to be == :missing
		end
	end
	
	with "#each" do
		it "yields once for each mapping" do
			map.add([0..5, 10..15], :first)
			map.add(6..9, :second)
			
			values = []
			map.each{|value| values << value}
			
			expect(values).to be == [:first, :second]
		end
	end
	
	with "#sample" do
		it "returns a mapped value" do
			expect(map.sample).to be_nil
			
			map.add([0..5, 10..15], :value)
			
			expect(map.sample).to be == :value
		end
	end
	
	with "#clear" do
		it "removes all mappings" do
			map.add(0..5, :value)
			map.clear
			
			expect(map.find(3)).to be_nil
			expect(map.sample).to be_nil
		end
	end
end
