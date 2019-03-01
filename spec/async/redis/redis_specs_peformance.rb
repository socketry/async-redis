require "rspec"
require 'async/redis'
require 'redis'
require 'benchmark/ips'


 Rspec.describe Async::Redis do
   describe '#redis_set_key'

   it "should be fast to set keys" do
     Benchmark.ips do |x|
       x.report("Set keys (async/redis)") do |times|
         endpoint = Async::Redis.local_endpoint
         client = Async::Redis::Client.new(endpoint)
            Async.run do
               while (times -= 1) >= 0
                client.set(["X","Y","Z"].sample, rand(1..10))
              end
            ensure
              client.close
        end
      end
      x.report("Set keys (redis-rb/redis)") do |times|
        redis = Redis.new
        while (times -= 1) >= 0
         redis.set(["X","Y","Z"].sample, rand(1..10))
       end
      end
    end
    x.compare!
  end
end
