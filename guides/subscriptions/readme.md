# Subscriptions

This guide explains how to use Redis pub/sub functionality with `async-redis` to publish and subscribe to messages.

## Usage

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
ensure
	client.close
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
	client.publish 'status.frontend', 'good'
	puts "Message sent!"
ensure
	client.close
end
```

To see pub/sub in action, you can run the listener in one terminal and the publisher in another. The listener will receive any messages sent by the publisher to the `status.frontend` channel:

```bash
$ ruby listener.rb
Listening for messages on 'status.frontend'...
Received: good
```

### How It Works

**Listener:**
- Uses the `subscribe` method with a channel name and block.
- The block receives a context object for listening to messages.
- `context.listen` returns an array: `[type, name, message]`.
- Runs continuously waiting for messages.

**Publisher:**
- Uses the `publish` method to send messages to a channel.
- Takes a channel name and message content.
- Sends the message and exits.

**Channel Communication:**
- Both listener and publisher use the same channel name (`'status.frontend'`).
- Messages are delivered in real-time when published.
- Multiple listeners can subscribe to the same channel.

## Message Format

When you call `context.listen`, it returns an array with three elements:

```ruby
type, name, message = context.listen
```

- **`type`**: The type of Redis pub/sub event. Common values include:
  - `"message"` - A regular published message.
  - `"subscribe"` - Confirmation that you've subscribed to a channel.
  - `"unsubscribe"` - Confirmation that you've unsubscribed from a channel.
  - `"pmessage"` - A message from a pattern subscription.
  - `"smessage"` - A message from a sharded channel subscription.

- **`name`**: The channel name where the message was received (e.g., `"status.frontend"`).

- **`message`**: The actual message content that was published.

**Note**: For pattern subscriptions (`pmessage`), the format is slightly different:
```ruby
type, pattern, name, message = context.listen
```
Where `pattern` is the pattern that matched, and `name` is the actual channel name.

### Example Output

```ruby
client.subscribe 'notifications' do |context|
	type, name, message = context.listen
	puts "Type: #{type}, Channel: #{name}, Message: #{message}"
end

# When someone publishes: client.publish('notifications', 'Hello World!')
# Output: Type: message, Channel: notifications, Message: Hello World!
```

## Multiple Channels

You can subscribe to multiple channels at once:

``` ruby
client.subscribe 'channel1', 'channel2', 'channel3' do |context|
	while true
		type, name, message = context.listen
		puts "Received on #{name}: #{message}"
	end
end
```

## Pattern Subscriptions

Redis also supports pattern-based subscriptions using `psubscribe`:

``` ruby
client.psubscribe 'status.*' do |context|
	while true
		response = context.listen
		
		if response.first == "pmessage"
			type, pattern, name, message = response
			puts "Pattern #{pattern} matched channel #{name}: #{message}"
		end
	end
end
```

## Mixing Regular and Pattern Subscriptions

You can mix regular channel subscriptions and pattern subscriptions on the same context:

``` ruby
client.subscribe 'exact-channel' do |context|
	# Add pattern subscription to the same context:
	context.psubscribe(['pattern.*'])
	
	while true
		response = context.listen
		
		case response.first
		when "message"
			type, name, message = response
			puts "Regular message on #{name}: #{message}"
		when "pmessage"
			type, pattern, name, message = response
			puts "Pattern #{pattern} matched #{name}: #{message}"
		end
	end
end
```

## Sharded Subscriptions

Redis 7.0 introduced sharded pub/sub for better scalability in cluster environments. You can use sharded subscriptions with the same `Subscribe` context:

``` ruby
client.ssubscribe 'user-notifications' do |context|
	while true
		type, name, message = context.listen
		puts "Sharded message on #{name}: #{message}"
	end
end
```

**Key differences from regular pub/sub:**
- Messages are distributed across cluster nodes for better performance.
- Only supports exact channel names (no pattern matching).
- Same message format as regular subscriptions: `[type, channel, message]`.
- Requires Redis 7.0+ and works best in cluster mode.

## Mixing All Subscription Types

Since all subscription types use the same `Subscribe` context, you can mix them freely:

``` ruby
client.subscribe 'exact-channel' do |context|
	# Add pattern and sharded subscriptions to the same context:
	context.psubscribe(['pattern.*'])
	context.ssubscribe(['shard-channel'])
	
	while true
		response = context.listen
		
		case response.first
		when "message"
			type, name, message = response
			puts "Regular message on #{name}: #{message}"
		when "pmessage"
			type, pattern, name, message = response
			puts "Pattern #{pattern} matched #{name}: #{message}"
		when "smessage"
			type, name, message = response
			puts "Sharded message on #{name}: #{message}"
		end
	end
end
```

## Important: Subscription Type Behavior

Redis supports mixing different subscription types on the same connection:

- ✅ **SUBSCRIBE + PSUBSCRIBE + SSUBSCRIBE**: All can be mixed on the same connection/context
- 🎯 **Unified Interface**: `async-redis` uses a single `Subscribe` context for all subscription types

**Benefits of the unified approach:**
- **Simplicity**: One context handles all subscription types
- **Flexibility**: Mix any combination of subscription types as needed
- **Consistency**: Same `listen` method handles all message types
- **Convenience**: No need to manage multiple contexts for different subscription types

## Error Handling

Always ensure proper cleanup of Redis connections:

``` ruby
Async do
	begin
		client.subscribe 'my-channel' do |context|
			# Handle messages...
		end
	rescue => error
		puts "Subscription error: #{error}"
	ensure
		client.close
	end
end
```
