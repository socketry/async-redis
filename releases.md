# Releases

## v0.11.2

  - Fix handling of IPv6 address literals, including those returned by Redis Cluster / Sentinel.

## v0.11.1

  - Correctly pass `@options` to `Async::Redis::Client` instances created by `Async::Redis::ClusterClient`.

## v0.10.0

### Add support for Redis Clusters

`Async::Redis::ClusterClient` is a new class that provides a high-level interface to a Redis Cluster. Due to the way clustering works, it does not provide the same interface as the `Async::Redis::Client` class. Instead, you must request an appropriate client for the key you are working with.

``` ruby
endpoints = [
	Async::Redis::Endpoint.parse("redis://redis-a"),
	Async::Redis::Endpoint.parse("redis://redis-b"),
	Async::Redis::Endpoint.parse("redis://redis-c"),
]

cluster_client = Async::Redis::ClusterClient.new(endpoints)

cluster_client.clients_for("key") do |client|
	puts client.get("key")
end
```

### Add support for Redis Sentinels

The previous implementation `Async::Redis::SentinelsClient` has been replaced with `Async::Redis::SentinelClient`. This new class uses `Async::Redis::Endpoint` objects to represent the sentinels and the master.

``` ruby
sentinels = [
	Async::Redis::Endpoint.parse("redis://redis-sentinel-a"),
	Async::Redis::Endpoint.parse("redis://redis-sentinel-b"),
	Async::Redis::Endpoint.parse("redis://redis-sentinel-c"),
]

master_client = Async::Redis::SentinelClient.new(sentinels)
slave_client = Async::Redis::SentinelClient.new(sentinels, role: :slave)

master_client.session do |session|
	session.set("key", "value")
end

slave_client.session do |session|
	puts session.get("key")
end
```

### Improved Integration Tests

Integration tests for Redis Cluster and Sentinel have been added, using `docker-compose` to start the required services and run the tests. These tests are not part of the default test suite and must be run separately. See the documentation in the `sentinel/` and `cluster/` directories for more information.
