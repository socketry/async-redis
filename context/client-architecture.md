# Client Architecture

This guide explains the different client types available in `async-redis` and when to use each one.

## Redis Deployment Patterns

Redis can be deployed in several configurations, each serving different scalability and availability needs:

### Single Instance
A single Redis server handles all operations. Simple to set up and manage, but limited by the capacity of one machine.

**Use when:**
- **Development**: Local development and testing.
- **Small applications**: Low traffic applications with simple caching needs.
- **Prototyping**: Getting started quickly without infrastructure complexity.

**Limitations:**
- **Single point of failure**: If Redis goes down, your application loses caching.
- **Memory constraints**: Limited by the memory of one machine.
- **CPU bottlenecks**: All operations processed by one Redis instance.

Use {ruby Async::Redis::Client} to connect to a single Redis instance.

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		client.set("cache:page", "cached content")
		content = client.get("cache:page")
		puts "Retrieved: #{content}"
	ensure
		client.close
	end
end
```

### Cluster (Sharded)

Multiple Redis nodes work together, with data automatically distributed across nodes based on key hashing. Provides horizontal scaling and high availability.

**Use when:**
- **Large datasets**: Data doesn't fit in a single Redis instance's memory.
- **High throughput**: Need to distribute load across multiple machines.
- **Horizontal scaling**: Want to add capacity by adding more nodes.

**Benefits:**
- **Automatic sharding**: Data distributed across nodes based on consistent hashing.
- **High availability**: Cluster continues operating if some nodes fail.
- **Linear scaling**: Add nodes to increase capacity and throughput.

Use {ruby Async::Redis::ClusterClient} to connect to a Redis cluster.

``` ruby
require "async/redis"

cluster_endpoints = [
	Async::Redis::Endpoint.new(hostname: "redis-1.example.com", port: 7000),
	Async::Redis::Endpoint.new(hostname: "redis-2.example.com", port: 7001),
	Async::Redis::Endpoint.new(hostname: "redis-3.example.com", port: 7002)
]

cluster_client = Async::Redis::ClusterClient.new(cluster_endpoints)

Async do
	begin
		# Data automatically distributed across nodes:
		cluster_client.set("cache:user:123", "user data")
		cluster_client.set("cache:user:456", "other user data")
		
		data = cluster_client.get("cache:user:123")
		puts "Retrieved from cluster: #{data}"
	ensure
		cluster_client.close
	end
end
```

Note that the cluster client automatically routes requests to the correct shard where possible.

### Sentinel (Master/Slave with Failover)

One master handles writes, multiple slaves handle reads, with sentinel processes monitoring for automatic failover.

**Use when:**
- **High availability**: Cannot tolerate Redis downtime.
- **Read scaling**: Many read operations, fewer writes.
- **Automatic failover**: Want automatic promotion of slaves to masters.

**Benefits:**
- **Automatic failover**: Sentinels promote slaves when master fails.
- **Read/write separation**: Distribute read load across slave instances.
- **Monitoring**: Built-in health checks and failure detection.

Use {ruby Async::Redis::SentinelClient} to connect to a Redis sentinel.

``` ruby
require "async/redis"

sentinel_endpoints = [
	Async::Redis::Endpoint.new(hostname: "sentinel-1.example.com", port: 26379),
	Async::Redis::Endpoint.new(hostname: "sentinel-2.example.com", port: 26379),
	Async::Redis::Endpoint.new(hostname: "sentinel-3.example.com", port: 26379)
]

sentinel_client = Async::Redis::SentinelClient.new(
	sentinel_endpoints,
	master_name: "mymaster"
)

Async do
	begin
		# Automatically connects to current master:
		sentinel_client.set("cache:critical", "important data")
		data = sentinel_client.get("cache:critical")
		puts "Retrieved from master: #{data}"
	ensure
		sentinel_client.close
	end
end
```
