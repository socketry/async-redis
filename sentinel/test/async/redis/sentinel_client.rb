# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require "async/clock"
require "async/redis/sentinel_client"
require "sus/fixtures/async"
require "securerandom"
require "openssl"

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
	
	def wait_until(duration: 0.001, repeats: 100)
		repeats.times do
			break if yield
			sleep duration
		end
	end
	
	it "should resolve slave address" do
		client.set(key, value)
		
		wait_until do
			slave_client.get(key) == value
		end
		
		expect(slave_client.get(key)).to be == value
	end
	
	it "can handle failover" do
		client.failover
		
		# We can still connect and do stuff:
		client.set(key, value)
		expect(client.get(key)).to be == value
	end
	
	with "endpoint options" do
		it "uses master_options for master connections" do
			master_options = {database: 1}
			client_with_options = subject.new(sentinels, master_options: master_options, role: :master)
			
			# Verify the client can set/get values (basic connectivity):
			client_with_options.set(key, value)
			expect(client_with_options.get(key)).to be == value
		end
		
		it "uses slave_options for slave connections when specified" do
			slave_options = {database: 2}
			slave_client_with_options = subject.new(sentinels, slave_options: slave_options, role: :slave)
			
			# Set data via master that also uses the same database:
			master_client_with_options = subject.new(sentinels, master_options: slave_options, role: :master)
			master_client_with_options.set(key, value)
			
			# Wait for replication and verify slave can read (basic connectivity):
			wait_until do
				slave_client_with_options.get(key) == value
			end
			
			expect(slave_client_with_options.get(key)).to be == value
		end
		
		it "falls back to master_options for slave connections when slave_options not specified" do
			master_options = {database: 3}
			slave_client_fallback = subject.new(sentinels, master_options: master_options, role: :slave)
			
			# Set data via master first:
			client_with_master_options = subject.new(sentinels, master_options: master_options, role: :master)
			client_with_master_options.set(key, value)
			
			# Wait for replication and verify slave can read using master options:
			wait_until do
				slave_client_fallback.get(key) == value
			end
			
			expect(slave_client_fallback.get(key)).to be == value
		end
		
		it "provides correct endpoint options for master role" do
			master_options = {database: 1, timeout: 5}
			slave_options = {database: 2, timeout: 10}
			
			client_with_both = subject.new(sentinels, master_options: master_options, slave_options: slave_options)
			
			expect(client_with_both.instance_variable_get(:@master_options)).to be == master_options
		end
		
		it "provides correct endpoint options for slave role" do
			master_options = {database: 1, timeout: 5}
			slave_options = {database: 2, timeout: 10}
			
			client_with_both = subject.new(sentinels, master_options: master_options, slave_options: slave_options)
			
			expect(client_with_both.instance_variable_get(:@slave_options)).to be == slave_options
		end
	end
end
