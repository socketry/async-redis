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
require 'benchmark/ips'

RSpec.describe "Client Performance" do
	it "should be fast to set keys" do
		Benchmark.ips do |x|
			x.report("async-redis") do |times|
				endpoint = Async::Redis.local_endpoint

				Async do
					client = Async::Redis::Client.new(endpoint)

					while (times -= 1) >= 0
						client.set(["X","Y","Z"].sample, rand(1..10))
					end

				# ensure
					client.close
				end
			end

			x.report("redis-rb") do |times|
				redis = Redis.new

				while (times -= 1) >= 0
					redis.set(["X","Y","Z"].sample, rand(1..10))
				end
			end
		end

		x.compare!
	end
end
