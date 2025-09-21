# Subscriptions

This guide explains how to use Redis pub/sub functionality with `async-redis` to publish and subscribe to messages.

Redis pub/sub enables real-time communication between different parts of your application or between different applications. It's perfect for broadcasting notifications, coordinating distributed systems, or building real-time features, provided you don't need reliable messaging.

Common use cases:
- **Real-time notifications**: Alert users about new messages, updates, or events.
- **System coordination**: Notify services about configuration changes or cache invalidation.
- **Live updates**: Push data changes to web interfaces or mobile apps.
- **Event-driven architecture**: Decouple services through asynchronous messaging.

## Overview

Redis provides 3 pub/sub mechanisms:
- **SUBSCRIBE**: Subscribe to specific channels by name.
- **PSUBSCRIBE**: Subscribe to channels matching patterns (e.g., `user.*`).
- **SSUBSCRIBE**: Sharded subscriptions for cluster environments (better performance).

## Subscribe

The `SUBSCRIBE` command lets you listen for messages on specific channels. This creates a persistent connection that receives messages as they're published.

Here's a simple notification system - first, create a listener:

``` ruby
require "async"
require "async/redis"

client = Async::Redis::Client.new

Async do
	client.subscribe "status.frontend" do |context|
		puts "Listening for messages on 'status.frontend'..."
		
		type, name, message = context.listen
		
		puts "Received: #{message}"
	end
end
```

In another part of your application, publish notifications:

``` ruby
require "async"
require "async/redis"

client = Async::Redis::Client.new

Async do
	puts "Publishing message..."
	client.publish "status.frontend", "good"
	puts "Message sent!"
end
```

To see pub/sub in action, you can run the listener in one terminal and the publisher in another. The listener will receive any messages sent by the publisher to the `status.frontend` channel:

```bash
$ ruby listener.rb
Listening for messages on 'status.frontend'...
Received: good
```

### Error Handling

Subscriptions are at-most-once delivery. In addition, subscriptions are stateful, meaning that they maintain their own internal state and can be affected by network issues or server restarts. In order to improve resilience, it's important to implement error handling and reconnection logic.

```ruby
require "async"
require "async/redis"

client = Async::Redis::Client.new

Async do
	client.subscribe "status.frontend" do |context|
		puts "Listening for messages on 'status.frontend'..."
		
		context.each do |type, name, message|
			puts "Received: #{message}"
		end
	end
rescue => error
	Console.warn(self, "Subscription failed", error)
	sleep 1
	retry
end
```

## Pattern Subscribe

When you need to listen to multiple related channels, patterns save you from subscribing to each channel individually. This is perfect for monitoring all user activities or all events from a specific service.

For example, to monitor all user-related events (`user.login`, `user.logout`, `user.signup`):

``` ruby
require "async"
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	client.psubscribe "status.*" do |context|
		puts "Listening for messages on 'status.*'..."
		
		type, pattern, name, message = context.listen
		
		puts "Received: #{message}"
	end
end
```

Note that an extra field, `pattern` is returned when using `PSUBSCRIBE`. This field indicates the pattern that was matched for the incoming message. This can be useful for logging or debugging purposes, as it allows you to see which pattern triggered the message delivery.

## Shard Subscribe

If you are working with a clustered environment, you can improve performance by limiting the scope of your subscriptions to specific shards. This can help reduce the amount of data that needs to be sent between shards and improve overall throughput.

To use sharded subscriptions, use a cluster client which supports sharded pub/sub:

``` ruby
require "async"
require "async/redis"

# endpoints = ...
cluster_client = Async::Redis::ClusterClient.new(endpoints)

Async do
	cluster_client.subscribe "status.frontend" do |context|
		puts "Listening for messages on 'status.frontend'..."
		
		type, name, message = context.listen
		
		puts "Received: #{message}"
	end
end
```

``` ruby
require "async"
require "async/redis"

# endpoints = ...
cluster_client = Async::Redis::ClusterClient.new(endpoints)

Async do
	puts "Publishing message..."
	cluster_client.publish("status.frontend", "good")
	puts "Message sent!"
end
```

### Clustered Subscriptions

While general `PUBLISH` and `SUBSCRIBE` will work on a cluster, they are less efficient as they require inter-shard communication. By default, the {ruby Async::Redis::ClusterClient} subscription mechanism defaults to `SSUBSCRIBE` and `SPUBLISH`, which are optimized for sharded environments. However, if using multiple subscriptions, internally, several connections will be made to the relevant shards, which increases the complexity.

#### Cluster Topology Changes and Subscription Invalidation

If the cluster is re-configured (e.g. adding or removing nodes, resharding), the subscription state may need to be re-established to account for the new topology. During this process, messages may be lost. This is expected as subscriptions are stateless.

**Important**: When any individual shard subscription fails (due to resharding, node failures, or network issues), the entire cluster subscription is invalidated and will stop delivering messages. This design ensures consistency and prevents partial subscription states that could lead to missed messages on some shards.

Common scenarios that trigger subscription invalidation:

- **Resharding operations**: When slots are migrated between nodes (`MOVED` errors)
- **Node failures**: When Redis nodes become unavailable
- **Network partitions**: When connections to specific shards are lost
- **Cluster reconfiguration**: When the cluster topology changes

Applications should be prepared to handle subscription failures and implement appropriate retry strategies.
