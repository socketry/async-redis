# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by Mikael Henriksson.
# Copyright, 2019-2023, by Samuel Williams.

require 'client_context'

describe Protocol::Redis::Methods::Hashes do
	include_context ClientContext
	
	let(:hash_field_one) {"beep-boop"}
	let(:hash_field_two) {"cowboy"}
	let(:hash_value) { "la la land" }
	let(:hash_key) {root["hash_key"]}
	
	it "can set a fields value" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hget(hash_key, hash_field_one)).to be == hash_value
		expect(client.hexists(hash_key, hash_field_one)).to be == true
		expect(client.hexists(hash_key, "notafield")).to be == false
		expect(client.hlen(hash_key)).to be == 1
	end
	
	it "can set multiple field values" do
		client.hmset(hash_key, hash_field_two, hash_value, hash_field_one, hash_value)
		
		expect(client.hmget(hash_key, hash_field_one, hash_field_two)).to be == [hash_value, hash_value]
		expect(client.hexists(hash_key, hash_field_one)).to be == true
		expect(client.hexists(hash_key, hash_field_two)).to be == true
		expect(client.hlen(hash_key)).to be == 2
	end
	
	it "can get keys" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hkeys hash_key).to be ==([hash_field_one])
	end
	
	it "can get values" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hvals hash_key).to be ==([hash_value])
	end
	
	it "can delete fields" do
		client.hset(hash_key, hash_field_one, hash_value)
		
		expect(client.hdel hash_key, hash_field_one).to be == 1
		expect(client.hget hash_key, hash_field_one).to be_nil
		expect(client.hlen hash_key).to be == 0
	end
end
