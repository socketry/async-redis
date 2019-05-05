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

RSpec.describe Async::Redis::Methods::Hashes, timeout: 5 do
	include_context Async::RSpec::Reactor
	include_context "database cleanup"

	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}

	let(:hash_field_one) {"beep-boop"}
	let(:hash_field_two) {"cowboy"}
	let(:prefix) {"async-redis:test:"}
	let(:hash_value) { "la la land" }
	let(:hash_key) {"async-redis:test:hash_key"}
	
	it "can set a fields value" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hget hash_key, hash_field_one).to be == hash_value
		expect(client.hexists hash_key, hash_field_one).to be == 1
		expect(client.hexists hash_key, "notafield").to be == 0
		expect(client.hlen hash_key).to be == 1

		client.close()
	end
	
	it "can set multiple field values" do
	  client.hmset(hash_key, hash_field_two, hash_value, hash_field_one, hash_value)
	  
	  expect(client.hmget hash_key, hash_field_one, hash_field_two).to be == [hash_value, hash_value]
	  expect(client.hexists hash_key, hash_field_one).to be == 1
		expect(client.hexists hash_key, hash_field_two).to be == 1
		expect(client.hlen hash_key).to be == 2
		
	  client.close()
	end
	
	it "can get keys" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hkeys hash_key).to eq([hash_field_one])

		client.close()
	end
	
	it "can get values" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hvals hash_key).to eq([hash_value])

		client.close()
	end
	
	it "can delete fields" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hdel hash_key, hash_field_one).to be == 1
		expect(client.hget hash_key, hash_field_one).to be_nil
		expect(client.hlen hash_key).to be == 0

		client.close()
	end
end
