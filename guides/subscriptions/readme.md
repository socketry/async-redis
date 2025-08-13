# Subscriptions

This guide explains how to use Redis pub/sub functionality with `async-redis` to publish and subscribe to messages.

## Overview

Redis actually has 3 mechanisms to support pub/sub - a general `SUBSCRIBE` command, a pattern-based `PSUBSCRIBE` command, and a sharded `SSUBSCRIBE` command for cluster environments. They mostly work the same way, but have different use cases.

## Subscribe

The `SUBSCRIBE` command is used to subscribe to one or more channels. When a message is published to a subscribed channel, the client receives the message in real-time.

First, let's create a simple listener that subscribes to messages on a channel:

``` ruby
require 'async'
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	client.subscribe 'status.frontend' do |context|
		puts "Listening for messages on 'status.frontend'..."
		
		type, name, message = context.listen
		
		puts "Received: #{message}"
	end
end
```

Now, let's create a publisher that sends messages to the same channel:

``` ruby
require 'async'
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	puts "Publishing message..."
	cluster_client.publish 'status.frontend', 'good'
	puts "Message sent!"
end
```

To see pub/sub in action, you can run the listener in one terminal and the publisher in another. The listener will receive any messages sent by the publisher to the `status.frontend` channel:

```bash
$ ruby listener.rb
Listening for messages on 'status.frontend'...
Received: good
```

## Pattern Subscribe

The `PSUBSCRIBE` command is used to subscribe to channels that match a given pattern. This allows clients to receive messages from multiple channels without subscribing to each one individually.

Let's replace the receiver in the above example:

``` ruby
require 'async'
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	client.psubscribe 'status.*' do |context|
		puts "Listening for messages on 'status.*'..."
		
		type, pattern, name, message = context.listen
		
		puts "Received: #{message}"
	end
end
```

Note that an extra field, `pattern` is returned when using `PSUBSCRIBE`. This field indicates the pattern that was matched for the incoming message. This can be useful for logging or debugging purposes, as it allows you to see which pattern triggered the message delivery.

## Shard Subscribe

If you are working with a clustered environment, you can improve performance by limiting the scope of your subscriptions to specific shards. This can help reduce the amount of data that needs to be sent over the network and improve overall throughput.

To use sharded subscriptions, you can use the `SSUBSCRIBE` command, which allows you to subscribe to a specific shard:

``` ruby
require 'async'
require 'async/redis'

# endpoints = ...
cluster_client = Async::Redis::ClusterClient.new(endpoints)

Async do
	cluster_client.subscribe 'status.frontend' do |context|
		puts "Listening for messages on 'status.frontend'..."
		
		type, name, message = context.listen
		
		puts "Received: #{message}"
	end
end
```

``` ruby
require 'async'
require 'async/redis'

# endpoints = ...
cluster_client = Async::Redis::ClusterClient.new(endpoints)

Async do
	puts "Publishing message..."
	cluster_client.publish('status.frontend', 'good')
	puts "Message sent!"
end
```

To see pub/sub in action, you can run the listener in one terminal and the publisher in another. The listener will receive any messages sent by the publisher to the `status.frontend` channel:

```bash
$ ruby listener.rb
Listening for messages on 'status.frontend'...
Received: good
```

```bash
$ ruby publisher.rb
Publishing message...
Message sent!
```