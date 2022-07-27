
def client
	require 'irb'
	require 'async/redis/client'
	
	endpoint = Async::Redis.local_endpoint
	client = Async::Redis::Client.new(endpoint)
	
	Async do
		binding.irb
	end
end
