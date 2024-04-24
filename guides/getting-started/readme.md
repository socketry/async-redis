# Getting Started

This guide explains how to use the `async-redis` gem to connect to a Redis server and perform basic operations.

## Installation

Add the gem to your project:

``` shell
$ bundle add async-redis
```

## Usage

### Basic Local Connection

``` ruby
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	puts client.info
ensure
	client.close
end
```

### Connecting to Redis SSL Endpoint

This example demonstrates parsing an environment variable with a `redis://` or SSL `rediss://` scheme, and demonstrates how you can specify SSL parameters on the SSLContext object.

``` ruby
require 'async/redis'

def make_redis_endpoint(uri)
	tcp_endpoint = ::IO::Endpoint.tcp(uri.hostname, uri.port)
	case uri.scheme
	when 'redis'
		tcp_endpoint
	when 'rediss'
		ssl_context = OpenSSL::SSL::SSLContext.new
		ssl_context.set_params(
			ca_file: "/path/to/ca.crt",
			cert: OpenSSL::X509::Certificate.new(File.read("client.crt")),
			key: OpenSSL::PKey::RSA.new(File.read("client.key")),
		)
		::IO::SSLEndpoint.new(tcp_endpoint, ssl_context: ssl_context)
	else
		raise ArgumentError
	end
end

endpoint = make_redis_endpoint(URI(ENV['REDIS_URL']))
client = Async::Redis::Client.new(endpoint)

# ...
```

### Variables

``` ruby
require 'async'
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	client.set('X', 10)
	puts client.get('X')
ensure
	client.close
end
```

### Subscriptions

``` ruby
require 'async'
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do |task|
	condition = Async::Condition.new
	
	publisher = task.async do
		condition.wait
		
		client.publish 'status.frontend', 'good'
	end
	
	subscriber = task.async do
		client.subscribe 'status.frontend' do |context|
			condition.signal # We are waiting for messages.
			
			type, name, message = context.listen
			
			pp type, name, message
		end
	end
ensure
	client.close
end
```