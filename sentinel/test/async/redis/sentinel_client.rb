# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'async/clock'
require 'async/redis/sentinel_client'
require 'sus/fixtures/async'
require 'securerandom'

describe Async::Redis::SentinelClient do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:master_host) {"redis://redis-master:6379"}
	let(:slave_host) {"redis://redis-slave:6379"}
	let(:sentinel_host) {"redis://redis-sentinel:26379"}
	
	let(:sentinels) {[
		Async::Redis::Endpoint.parse(sentinel_host)
	]}
	
	let(:client) {subject.new(sentinels)}
	let(:slave_client) {subject.new(sentinels, role: :slave)}
	
	let(:master_client) {Async::Redis::Client.new(Endpoint.parse(master_host))}
	
	let(:key) {"sentinel-test:#{SecureRandom.hex(8)}"}
	let(:value) {"sentinel-test-value"}
	
	it "should resolve master address" do
		client.set(key, value)
		expect(client.get(key)).to be == value
	end
	
	it "should resolve slave address" do
		client.set(key, value)
		
		# It takes a while to replicate:
		while true
			break if slave_client.get(key) == value
			sleep 0.01
		end
		
		expect(slave_client.get(key)).to be == value
	end
	
	it "can handle failover" do
		client.failover
		
		# We can still connect and do stuff:
		client.set(key, value)
		expect(client.get(key)).to be == value
	end
end
