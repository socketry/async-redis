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
require "async/redis"

Async do
	endpoint = Async::Redis.local_endpoint(
		# Optional database index:
		database: 1,
		# Optional credentials:
		credentials: ["username", "password"]
	)
	
	client = Async::Redis::Client.new(endpoint)
	puts client.info
	
	client.set("mykey", "myvalue")
	puts client.get("mykey")
end
```

You can also encode this information in a URL:



### Connecting to Redis SSL Endpoint

This example demonstrates parsing an environment variable with a `redis://` or SSL `rediss://` scheme, and demonstrates how you can specify SSL parameters on the SSLContext object.

``` ruby
require "async/redis"

ssl_context = OpenSSL::SSL::SSLContext.new.tap do |context|
	# Load the certificate store:
	context.cert_store = OpenSSL::X509::Store.new.tap do |store|
		store.add_file(Rails.root.join("config/redis.pem").to_s)
	end
	
	# Load the certificate:
	context.cert = OpenSSL::X509::Certificate.new(File.read(
		Rails.root.join("config/redis.crt")
	))
	
	# Load the private key:
	context.key = OpenSSL::PKey::RSA.new(
		Rails.application.credentials.services.redis.private_key
	)
	
	# Ensure the connection is verified according to the above certificates:
	context.verify_mode = OpenSSL::SSL::VERIFY_PEER
end

# e.g. REDIS_URL=rediss://:PASSWORD@redis.example.com:12345
endpoint = Async::Redis::Endpoint.parse(ENV["REDIS_URL"], ssl_context: ssl_context)
client = Async::Redis::Client.new(endpoint)
Sync do
	puts client.call("PING")
end
```

### Variables

``` ruby
require "async"
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	client.set("X", 10)
	puts client.get("X")
ensure
	client.close
end
```

## Next Steps

- [Subscriptions](../subscriptions/) - Learn how to use Redis pub/sub functionality for real-time messaging.