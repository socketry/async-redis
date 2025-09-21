# Streams

This guide explains how to use Redis streams with `async-redis` for reliable message processing and event sourcing.

Streams are designed for high-throughput message processing and event sourcing. They provide durability, consumer groups for load balancing, and automatic message acknowledgment.

Use streams when you need:
- **Event sourcing**: Capture all changes to application state.
- **Message queues**: Reliable message delivery with consumer groups.
- **Audit logs**: Immutable record of system events.
- **Real-time analytics**: Process streams of user events or metrics.

## Stream Creation and Consumption

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Add entries to stream:
		events = [
			{ "type" => "user_signup", "user_id" => "123", "email" => "alice@example.com" },
			{ "type" => "purchase", "user_id" => "123", "amount" => "29.99" },
			{ "type" => "user_signup", "user_id" => "456", "email" => "bob@example.com" }
		]
		
		events.each do |event|
			entry_id = client.xadd("user_events", "*", event)
			puts "Added event with ID: #{entry_id}"
		end
		
		# Read from stream:
		entries = client.xrange("user_events", "-", "+")
		puts "Stream entries:"
		entries.each do |entry_id, fields|
			puts "  #{entry_id}: #{fields}"
		end
		
		# Read latest entries:
		latest = client.xrevrange("user_events", "+", "-", count: 2)
		puts "Latest 2 entries: #{latest}"
		
	ensure
		client.close
	end
end
```

## Reading New Messages

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Add some initial events:
		client.xadd("notifications", "*", "type" => "welcome", "user_id" => "123")
		client.xadd("notifications", "*", "type" => "reminder", "user_id" => "456")
		
		# Read only new messages (blocking):
		puts "Waiting for new messages..."
		
		# This will block until new messages arrive:
		messages = client.xread("BLOCK", 5000, "STREAMS", "notifications", "$")
		
		if messages && !messages.empty?
			stream_name, entries = messages[0]
			puts "Received #{entries.length} new messages:"
			entries.each do |entry_id, fields|
				puts "  #{entry_id}: #{fields}"
			end
		else
			puts "No new messages received within timeout"
		end
		
	ensure
		client.close
	end
end
```

## Consumer Groups

Consumer groups enable multiple workers to process messages in parallel while ensuring each message is processed exactly once:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Create consumer group:
		begin
			client.xgroup("CREATE", "user_events", "processors", "0", "MKSTREAM")
			puts "Created consumer group 'processors'"
		rescue Protocol::Redis::ServerError => e
			puts "Consumer group already exists: #{e.message}"
		end
		
		# Add some test events:
		3.times do |i|
			client.xadd("user_events", "*", "event" => "test_#{i}", "timestamp" => Time.now.to_f)
		end
		
		# Consume messages:
		consumer_name = "worker_1"
		messages = client.xreadgroup("GROUP", "processors", consumer_name, "COUNT", 2, "STREAMS", "user_events", ">")
		
		if messages && !messages.empty?
			stream_name, entries = messages[0]
			puts "Consumer #{consumer_name} received #{entries.length} messages:"
			
			entries.each do |entry_id, fields|
				puts "  Processing #{entry_id}: #{fields}"
				
				# Simulate message processing:
				sleep 0.1
				
				# Acknowledge message processing:
				client.xack("user_events", "processors", entry_id)
				puts "  Acknowledged #{entry_id}"
			end
		else
			puts "No new messages for consumer #{consumer_name}"
		end
		
	ensure
		client.close
	end
end
```

## Multiple Consumers

Demonstrate load balancing across multiple consumers:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do |task|
	begin
		# Create consumer group:
		begin
			client.xgroup("CREATE", "work_queue", "workers", "0", "MKSTREAM")
		rescue Protocol::Redis::ServerError
			# Group already exists
		end
		
		# Producer task - add work items:
		producer = task.async do
			10.times do |i|
				client.xadd("work_queue", "*", 
					"task_id" => i, 
					"data" => "work_item_#{i}",
					"priority" => rand(1..5)
				)
				puts "Added work item #{i}"
				sleep 0.5
			end
		end
		
		# Consumer tasks - process work items:
		consumers = 3.times.map do |worker_id|
			task.async do
				consumer_name = "worker_#{worker_id}"
				
				loop do
					messages = client.xreadgroup(
						"GROUP", "workers", consumer_name,
						"COUNT", 1,
						"BLOCK", 1000,
						"STREAMS", "work_queue", ">"
					)
					
					if messages && !messages.empty?
						stream_name, entries = messages[0]
						
						entries.each do |entry_id, fields|
							puts "#{consumer_name} processing: #{fields}"
							
							# Simulate work:
							sleep rand(0.1..0.5)
							
							# Acknowledge completion:
							client.xack("work_queue", "workers", entry_id)
							puts "#{consumer_name} completed: #{entry_id}"
						end
					end
				end
			end
		end
		
		# Wait for producer to finish:
		producer.wait
		
		# Let consumers process remaining work:
		sleep 3
		
		# Stop all consumers:
		consumers.each(&:stop)
		
	ensure
		client.close
	end
end
```

## Message Acknowledgment and Recovery

Handle message acknowledgment and recover from failures:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Check for pending messages:
		pending_info = client.xpending("user_events", "processors")
		if pending_info && pending_info[0] > 0
			puts "Found #{pending_info[0]} pending messages"
			
			# Get detailed pending information:
			pending_details = client.xpending("user_events", "processors", "-", "+", 10)
			pending_details.each do |entry_id, consumer, idle_time, delivery_count|
				puts "Message #{entry_id} pending for #{idle_time}ms (delivered #{delivery_count} times to #{consumer})"
				
				# Claim long-pending messages for reprocessing:
				if idle_time > 60000  # 1 minute
					claimed = client.xclaim("user_events", "processors", "recovery_worker", 60000, entry_id)
					if claimed && !claimed.empty?
						puts "Claimed message #{entry_id} for reprocessing"
						
						# Process the claimed message:
						claimed.each do |claimed_id, fields|
							puts "Reprocessing: #{fields}"
							# ... process message ...
						end
						
						# Acknowledge after successful processing:
						client.xack("user_events", "processors", entry_id)
						puts "Acknowledged recovered message #{entry_id}"
					end
				end
			end
		else
			puts "No pending messages found"
		end
		
	ensure
		client.close
	end
end
```

## Stream Information and Management

Monitor and manage stream health:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Get stream information:
		stream_info = client.xinfo("STREAM", "user_events")
		puts "Stream info: #{stream_info}"
		
		# Get consumer group information:
		begin
			groups_info = client.xinfo("GROUPS", "user_events")
			puts "Consumer groups:"
			groups_info.each do |group|
				group_data = Hash[*group]
				puts "  Group: #{group_data['name']}, Consumers: #{group_data['consumers']}, Pending: #{group_data['pending']}"
			end
		rescue Protocol::Redis::ServerError
			puts "No consumer groups exist for this stream"
		end
		
		# Get consumers in a group:
		begin
			consumers_info = client.xinfo("CONSUMERS", "user_events", "processors")
			puts "Consumers in 'processors' group:"
			consumers_info.each do |consumer|
				consumer_data = Hash[*consumer]
				puts "  Consumer: #{consumer_data['name']}, Pending: #{consumer_data['pending']}, Idle: #{consumer_data['idle']}ms"
			end
		rescue Protocol::Redis::ServerError
			puts "Consumer group 'processors' does not exist"
		end
		
		# Trim stream to keep only recent messages:
		trimmed = client.xtrim("user_events", "MAXLEN", "~", 1000)
		puts "Trimmed #{trimmed} messages from stream"
		
	ensure
		client.close
	end
end
```
