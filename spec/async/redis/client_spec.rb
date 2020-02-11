# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/clock'
require 'async/redis/client'

RSpec.describe Async::Redis::Client, timeout: 5 do
	include_context Async::RSpec::Reactor
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	
	it "should connect to redis server" do
		result = client.call("INFO")
		
		expect(result).to include('redis_version')
		
		client.close
	end
	
	let(:string_key) {"async-redis:test:string"}
	let(:test_string) {"beep-boop"}
	
	it "can set simple string and retrieve it" do
		client.call("SET", string_key, test_string)
		
		response = client.call("GET", string_key)
		expect(response).to be == test_string
		
		client.close
	end
	
	let(:list_key) {"async-redis:test:list"}
	
	it "can add items to list and retrieve them" do
		client.call("LTRIM", list_key, 0, 0)
		
		response = client.call("LPUSH", list_key, "World", "Hello")
		expect(response).to be > 0
		
		response = client.call("LRANGE", list_key, 0, 1)
		expect(response).to be == ["Hello", "World"]
		
		client.close
	end
	
	it "can timeout" do
		duration = Async::Clock.measure do
			result = client.call("BLPOP", "SLEEP", 1)
		end
		
		expect(duration).to be_within(20).percent_of(1)
		
		client.close
	end
	
	it "can propagate errors back from the server" do
		# ERR
		expect{client.call("NOSUCHTHING", 0, 85)}.to raise_error(Async::Redis::ServerError)
		
		# WRONGTYPE
		client.call("LPUSH", list_key, "World", "Hello")
		expect{client.call("GET", list_key)}.to raise_error(Async::Redis::ServerError)
		
		client.close
	end
	
	it "retrieves large responses from redis", timeout: 30 do
		size = 5000
		
		client.call("DEL", list_key)
		size.times {|i| client.call("RPUSH", list_key, i) }
		
		response = client.call("LRANGE", list_key, 0, size - 1)
		
		expect(response).to eq (0...size).map(&:to_s)
		
		client.close
	end

	it "can use pipelining" do
		client.pipeline do |context|
			client.set 'async_redis_test_key_1', 'a'
			client.set 'async_redis_test_key_2', 'b'
			
			results = context.collect do
				context.get 'async_redis_test_key_1'
				context.get 'async_redis_test_key_2'
			end
			
			expect(results).to be == ['a', 'b']
		end
		
		client.close
	end
end
