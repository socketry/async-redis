# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# Copyright, 2018, by Huba Nagy.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/redis/client'
require_relative '../database_cleanup'

RSpec.describe Async::Redis::Methods::Lists, timeout: 5 do
	include_context Async::RSpec::Reactor
	include_context "database cleanup"

	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}

	let(:list_a) {'async-redis:test:list_a'}
	let(:list_b) {'async-redis:test:list_b'}
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

		client.close
	end

	it "can conditionally push and pop items from lists" do

	end

	it "can get, set and remove values at specific list indexes" do

	end

	it "can get a list slice" do
		client.rpush(list_a, test_list)

		slice_size = list_a.size/2

		expect(client.lrange(list_a, 0, slice_size - 1))
			.to match_array test_list.take(slice_size).map(&:to_s)

		client.close
	end

	it "can trim lists" do

	end
end
