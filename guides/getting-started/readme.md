# Getting Started

This guide explains how to use the `async-redis` gem to connect to a Redis server and perform basic operations.

## Installation

Add the gem to your project:

``` shell
$ bundle add async-redis
```

## Core Concepts

`async-redis` has several core concepts:

- A {ruby Async::Redis::Client} which represents the main entry point for Redis operations.
- An {ruby Async::Redis::Endpoint} which represents connection details including host, port, and authentication.
- An {ruby Async::Redis::Context::Generic} which represents an actual connection to the Redis server.

## Usage

This example shows how to connect to a local Redis server:

``` ruby
require "async/redis"

Async do
	# Create a local endpoint with optional configuration:
	endpoint = Async::Redis.local_endpoint(
		# Optional database index:
		database: 1,
		# Optional credentials:
		credentials: ["username", "password"]
	)
	
	client = Async::Redis::Client.new(endpoint)
	
	# Get server information:
	puts client.info
	
	# Store and retrieve a value:
	client.set("mykey", "myvalue")
	puts client.get("mykey")
ensure
	# Always close the client to free resources:
	client&.close
end
```

### Connecting to Redis using SSL

This example demonstrates parsing an environment variable with a `redis://` or SSL `rediss://` scheme, and demonstrates how you can specify SSL parameters on the SSLContext object.

``` ruby
require "async/redis"

# Parse Redis URL with SSL support.
# Example: REDIS_URL=rediss://:PASSWORD@redis.example.com:12345
endpoint = Async::Redis::Endpoint.parse(ENV["REDIS_URL"])
client = Async::Redis::Client.new(endpoint)

Sync do
	puts client.call("PING")
ensure
	client&.close
end
```

Alternatively, you can parse a URL and pass credentials as options:

``` ruby
require "async/redis"

# Parse URL and add credentials:
endpoint = Async::Redis::Endpoint.parse(
	"rediss://redis.example.com:6379",
	credentials: ["username", "password"]
	# Optional SSL context:
	# ssl_context: ...
)

client = Async::Redis::Client.new(endpoint)

Async do
	puts client.call("PING")
ensure
	client&.close
end
```
