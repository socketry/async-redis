# frozen_string_literal: true

# Copyright, 2019, by Pierre Montelle.
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

require 'async/redis'
require 'redis'

require 'benchmark'
require 'benchmark/ips'

RSpec.xdescribe "Client Performance", timeout: nil do
	include_context Async::RSpec::Reactor
	
	let(:keys) {["X","Y","Z"].freeze}
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:async_client) {Async::Redis::Client.new(endpoint)}
	let(:redis_client) {Redis.new}
	let(:redis_client_hiredis) {Redis.new(driver: :hiredis)}
	
	it "should be fast to set keys" do
		Benchmark.ips do |benchmark|
			benchmark.report("async-redis (pool)") do |times|
				key = keys.sample
				value = times.to_s
				
				i = 0; while i < times; i += 1
					async_client.set(key, value)
					expect(async_client.get(key)).to be == value
				end
			end
			
			benchmark.report("async-redis (pipeline)") do |times|
				key = keys.sample
				value = times.to_s
				
				async_client.pipeline do |pipeline|
					sync = pipeline.sync
					
					i = 0; while i < times; i += 1
						pipeline.set(key, value)
						expect(sync.get(key)).to be == value
					end
				end
			end
			
			benchmark.report("redis-rb") do |times|
				key = keys.sample
				value = times.to_s
				
				i = 0; while i < times; i += 1
					redis_client.set(key, value)
					expect(redis_client.get(key)).to be == value
				end
			end

			# Hiredis is C and not supported in JRuby and TruffleRuby.
			if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
				benchmark.report("redis-rb (hiredis)") do |times|
					key = keys.sample
					value = times.to_s

					i = 0; while i < times; i += 1
						redis_client_hiredis.set(key, value)
						expect(redis_client_hiredis.get(key)).to be == value
					end
				end
			end

			
			benchmark.compare!
		end
		
		async_client.close
		redis_client.close
	end
end
