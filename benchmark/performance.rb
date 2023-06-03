# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by Pierre Montelle.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2019, by David Ortiz.

require 'async/redis'

require 'redis'
require 'redis/connection/hiredis'

require 'benchmark'
require 'benchmark/ips'

keys = ["X","Y","Z"].freeze
endpoint = Async::Redis.local_endpoint
async_client = Async::Redis::Client.new(endpoint)
redis_client = Redis.new
redis_client_hiredis = Redis.new(driver: :hiredis)

Sync do
	Benchmark.ips do |benchmark|
		benchmark.report("async-redis (pool)") do |times|
			key = keys.sample
			value = times.to_s
			
			i = 0; while i < times; i += 1
				async_client.set(key, value)
			end
		end
		
		benchmark.report("async-redis (pipeline)") do |times|
			key = keys.sample
			value = times.to_s
			
			async_client.pipeline do |pipeline|
				sync = pipeline.sync
				
				i = 0; while i < times; i += 1
					pipeline.set(key, value)
				end
			end
		end
		
		benchmark.report("redis-rb") do |times|
			key = keys.sample
			value = times.to_s
			
			i = 0; while i < times; i += 1
				redis_client.set(key, value)
			end
		end
		
		benchmark.report("redis-rb (hiredis)") do |times|
			key = keys.sample
			value = times.to_s
			
			i = 0; while i < times; i += 1
				redis_client_hiredis.set(key, value)
			end
		end
		
		benchmark.compare!
	end
	
	async_client.close
	redis_client.close
end
