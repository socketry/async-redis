# Transactions and Pipelines

This guide explains how to use Redis transactions and pipelines with `async-redis` for atomic operations and improved performance.

By default, each command (e.g. `GET key`) acquires a connection from the client, runs the command, returns the result and releases the connection back to the client's connection pool. This may be inefficient for some use cases, and so there are several ways to group together operations that run on the same connection.

## Transactions (MULTI/EXEC)

Transactions ensure that multiple Redis commands execute atomically - either all commands succeed, or none of them do. This is crucial when you need to maintain data consistency, such as transferring money between accounts or updating related fields together.

Use transactions when you need:
- **Atomic updates**: Multiple operations that must all succeed or all fail.
- **Data consistency**: Keeping related data in sync across multiple keys.
- **Preventing partial updates**: Avoiding situations where only some of your changes are applied.

Redis transactions queue commands and execute them all at once:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Execute commands atomically:
		results = client.transaction do |context|
			context.multi
			
			# Queue commands for atomic execution:
			context.set("user:1:name", "Alice")
			context.set("user:1:email", "alice@example.com")
			context.incr("user:count")
			
			# Execute all queued commands:
			context.execute
		end
		
		puts "Transaction results: #{results}"
		
	ensure
		client.close
	end
end
```

### Watch/Unwatch for Optimistic Locking

When multiple clients might modify the same data simultaneously, you need to handle race conditions. Redis WATCH provides optimistic locking - the transaction only executes if watched keys haven't changed since you started watching them.

This is essential for scenarios like:
- Updating counters or balances where the current value matters.
- Implementing atomic increment operations with business logic.
- Preventing lost updates in concurrent environments.

Here's how to implement safe concurrent updates:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Initialize counter.
		client.set("counter", 0)
		
		# Optimistic locking example:
		5.times do |i|
			success = false
			attempts = 0
			
			while !success && attempts < 3
				attempts += 1
				
				result = client.transaction do |context|
					# Watch the counter for changes (executes immediately):
					context.watch("counter")
					
					# Read current value (executes immediately):
					current_value = client.get("counter").to_i
					new_value = current_value + 1
					
					# Start transaction - commands after this are queued, not executed:
					context.multi
					
					# Queue commands (these return "QUEUED", don't execute yet):
					context.set("counter", new_value)
					context.set("last_update", Time.now.to_f)
					
					# Execute all queued commands atomically.
					# Returns nil if watched key was modified by another client:
					context.execute
				end
				
				if result
					puts "Increment #{i + 1} succeeded: #{result}"
					success = true
				else
					puts "Increment #{i + 1} failed, retrying (attempt #{attempts})"
					sleep 0.01
				end
			end
		end
		
		final_value = client.get("counter")
		puts "Final counter value: #{final_value}"
		
	ensure
		client.close
	end
end
```

## Pipelines

When you need to execute many Redis commands quickly, sending them one-by-one creates network latency bottlenecks. Pipelines solve this by batching multiple commands together, dramatically reducing round-trip time.

Use pipelines when you need:
- **Better performance**: Reduce network round trips for bulk operations.
- **High throughput**: Process hundreds or thousands of commands efficiently.
- **Independent operations**: Commands that don't depend on each other's results.

Unlike transactions, pipeline commands are not atomic - some may succeed while others fail:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Execute commands in a pipeline:
		results = client.pipeline do |context|
			# Commands are buffered and flushed if needed:
			context.set("pipeline:1", "value1")
			context.set("pipeline:2", "value2")
			context.set("pipeline:3", "value3")
			
			context.get("pipeline:1")
			context.get("pipeline:2")
			context.get("pipeline:3")
			
			# Flush and collect the results from all previous commands:
			context.collect
		end
		
		puts "Pipeline results: #{results}"
		
	ensure
		client.close
	end
end
```

### Synchronous Pipeline Operations

When you need immediate results from individual commands within a pipeline, use `context.sync`:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		client.pipeline do |context|
			# Set values using pipeline - no immediate response:
			context.set("async_key_1", "value1")
			context.set("async_key_2", "value2")
			
			# Get immediate response using sync:
			immediate_result = context.sync.get("async_key_1")
			puts "Immediate result: #{immediate_result}"
			
			# Continue with pipelined operations:
			context.get("async_key_2")
			
			# Collect remaining pipelined results:
			context.collect
		end
		
	ensure
		client.close
	end
end
```

Use `context.sync` when you need to:
- **Check values mid-pipeline**: Verify data before continuing with more operations.
- **Conditional logic**: Make decisions based on current Redis state.
- **Debugging**: Get immediate feedback during pipeline development.

Note that `sync` operations execute immediately and flush pending responses, so use them strategically to maintain pipeline performance benefits.
