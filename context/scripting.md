# Scripting

This guide explains how to use Redis Lua scripting with `async-redis` for atomic operations and advanced data processing.

Lua scripting moves complex logic to the Redis server, ensuring atomicity and reducing network round trips. This is essential for operations that need to read, compute, and write data atomically.

Critical for:
- **Atomic business logic**: Complex operations that must be consistent.
- **Performance optimization**: Reduce network calls for multi-step operations.
- **Race condition prevention**: Ensure operations complete without interference.
- **Custom data structures**: Implement specialized behaviors not available in standard Redis commands.

## Basic Script Loading and Execution

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Simple Lua script:
		increment_script = <<~LUA
			local key = KEYS[1]
			local increment = tonumber(ARGV[1])
			local current = redis.call('GET', key) or 0
			local new_value = tonumber(current) + increment
			redis.call('SET', key, new_value)
			return new_value
		LUA
		
		# Load and execute script:
		script_sha = client.script("LOAD", increment_script)
		puts "Script loaded with SHA: #{script_sha}"
		
		# Execute script by SHA:
		result = client.evalsha(script_sha, 1, "counter", 5)
		puts "Counter incremented to: #{result}"
		
		# Execute script directly:
		result = client.eval(increment_script, 1, "counter", 3)
		puts "Counter incremented to: #{result}"
		
	ensure
		client.close
	end
end
```

## Parameter Passing and Return Values

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Script with multiple parameters and complex return:
		session_update_script = <<~LUA
			local session_key = KEYS[1]
			local user_id = ARGV[1]
			local username = ARGV[2]
			local increment_activity = ARGV[3] == 'true'
			
			-- Update session fields:
			redis.call('HSET', session_key, 'user_id', user_id, 'username', username)
			
			-- Conditionally increment activity count:
			local activity_count = 0
			if increment_activity then
				activity_count = redis.call('HINCRBY', session_key, 'activity_count', 1)
			else
				activity_count = tonumber(redis.call('HGET', session_key, 'activity_count') or 0)
			end
			
			-- Update last activity timestamp:
			redis.call('HSET', session_key, 'last_activity', redis.call('TIME')[1])
			
			-- Return session data:
			return {
				user_id,
				username,
				activity_count,
				redis.call('HGET', session_key, 'last_activity')
			}
		LUA
		
		# Execute with parameters:
		session_id = "session:" + SecureRandom.hex(16)
		result = client.eval(session_update_script, 1, session_id, "12345", "alice", "true")
		user_id, username, activity_count, last_activity = result
		
		puts "Updated session for #{username} (ID: #{user_id})"
		puts "Activity count: #{activity_count}, Last activity: #{last_activity}"
		
	ensure
		client.close
	end
end
```

## Script Caching Pattern

Instead of complex script managers, use a simple caching pattern with fallback:

``` ruby
require "async/redis"

class JobQueue
	# Define scripts as class constants:
	DEQUEUE_SCRIPT = <<~LUA
		local queue_key = KEYS[1]
		local processing_key = KEYS[2]
		local current_time = ARGV[1]
		
		-- Get job from queue:
		local job = redis.call('LPOP', queue_key)
		if not job then
			return nil
		end
		
		-- Add to processing set with timestamp:
		redis.call('ZADD', processing_key, current_time, job)
		
		return job
	LUA
	
	COMPLETE_SCRIPT = <<~LUA
		local processing_key = KEYS[1]
		local job_data = ARGV[1]
		
		-- Remove job from processing set:
		local removed = redis.call('ZREM', processing_key, job_data)
		
		return removed
	LUA
	
	def initialize(client, queue_name)
		@client = client
		@queue_name = queue_name
		@processing_name = "#{queue_name}:processing"
		
		# Load all scripts at initialization:
		@dequeue_sha = @client.script("LOAD", DEQUEUE_SCRIPT)
		@complete_sha = @client.script("LOAD", COMPLETE_SCRIPT)
	end
	
	def dequeue_job
		@client.evalsha(@dequeue_sha, 2, @queue_name, @processing_name, Time.now.to_i)
	end
	
	def complete_job(job_data)
		@client.evalsha(@complete_sha, 1, @processing_name, job_data)
	end
	
	def enqueue_job(job_data)
		@client.rpush(@queue_name, job_data)
	end
	
	def cleanup_stale_jobs(timeout_seconds = 300)
		cutoff_time = Time.now.to_i - timeout_seconds
		stale_jobs = @client.zrangebyscore(@processing_name, "-inf", cutoff_time)
		
		if stale_jobs.any?
			puts "Found #{stale_jobs.length} stale jobs, requeueing..."
			
			# Move stale jobs back to queue:
			stale_jobs.each do |job|
				@client.lpush(@queue_name, job)
			end
			
			# Remove from processing set:
			@client.zremrangebyscore(@processing_name, "-inf", cutoff_time)
		end
	end
end

# Usage:
endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		queue = JobQueue.new(client, "work_queue")
		
		# Add some jobs:
		5.times do |i|
			queue.enqueue_job("job_#{i}")
			puts "Enqueued job_#{i}"
		end
		
		# Process jobs:
		3.times do |i|
			job = queue.dequeue_job
			if job
				puts "Processing: #{job}"
				# Simulate work...
				sleep 0.1
				puts "Completed: #{job}"
			else
				puts "No jobs available"
			end
		end
		
		# Check for stale jobs:
		queue.cleanup_stale_jobs(60)
		
	ensure
		client.close
	end
end
```

## Best Practices

### When to Use Scripts

Use Lua scripts when you need:
- **Atomic multi-step operations**: Multiple Redis commands that must succeed or fail together.
- **Complex conditional logic**: Operations that depend on current Redis state.
- **Performance optimization**: Reduce network round trips for complex operations.
- **Race condition prevention**: Ensure operations complete without interference.

### When Not to Use Scripts

Avoid scripts for:
- **Simple operations**: Single Redis commands don't need scripting.
- **Long-running operations**: Scripts block the Redis server.
- **Operations with external dependencies**: Scripts can't make network calls.
- **Frequently changing logic**: Scripts are cached and harder to update.

### Script Performance Tips

- **Keep scripts short**: Long scripts block other operations.
- **Use local variables**: Avoid repeated Redis calls for the same data.
- **Cache scripts**: Use `EVALSHA` instead of `EVAL` for better performance.
- **Handle script cache misses**: Implement fallback logic for `NOSCRIPT` errors.
- **Validate inputs early**: Check parameters before performing operations.

Scripts provide powerful atomic operations but should be used judiciously to maintain Redis performance and simplicity.
