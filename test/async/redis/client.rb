# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2019, by David Ortiz.

require 'async/clock'
require 'async/redis/client'
require 'sus/fixtures/async'
require 'securerandom'

describe Async::Redis::Client do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	
	# Some of these tests are a little slow.
	let(:timeout) {10}
	
	it "should connect to redis server" do
		result = client.call("INFO")
		
		expect(result).to be(:include?, 'redis_version')
		
		client.close
	end
	
	let(:string_key) {"async-redis:test:#{SecureRandom.uuid}:string"}
	let(:test_string) {"beep-boop"}
	
	it "can set simple string and retrieve it" do
		client.call("SET", string_key, test_string)
		
		response = client.call("GET", string_key)
		expect(response).to be == test_string
		
		client.close
	end
	
	let(:list_key) {"async-redis:test::#{SecureRandom.uuid}:list"}
	
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
			result = client.call("BLPOP", "SLEEP", 0.1)
		end
		
		expect(duration).to be_within(100).percent_of(0.1)
		
		client.close
	end
	
	it "can propagate errors back from the server" do
		# ERR
		expect{client.call("NOSUCHTHING", 0, 85)}.to raise_exception(Async::Redis::ServerError)
		
		# WRONGTYPE
		client.call("LPUSH", list_key, "World", "Hello")
		expect{client.call("GET", list_key)}.to raise_exception(Async::Redis::ServerError)
		
		client.close
	end
	
	it "retrieves large responses from redis" do
		size = 1000
		
		client.call("DEL", list_key)
		size.times {|i| client.call("RPUSH", list_key, i) }
		
		response = client.call("LRANGE", list_key, 0, size - 1)
		
		expect(response).to be == (0...size).map(&:to_s)
		
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
