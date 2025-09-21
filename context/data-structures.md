# Data Structures and Operations

This guide explains how to work with Redis data types and operations using `async-redis`.

## Strings

Strings are Redis's most versatile data type, perfect for caching values, storing user sessions, implementing counters, or holding configuration data. Despite the name, they can store any binary data up to 512MB.

Common use cases:
- **Caching**: Store computed results, API responses, or database query results.
- **Counters**: Page views, user scores, rate limiting.
- **Sessions**: User authentication tokens and session data.
- **Configuration**: Application settings and feature flags.

### Basic Operations

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Cache API responses:
		client.set("cache:api:users", '{"users": [{"id": 1, "name": "Alice"}]}')
		client.expire("cache:api:users", 300)  # 5 minute cache
		
		cached_response = client.get("cache:api:users")
		puts "Cached API response: #{cached_response}"
		
		# Implement counters:
		client.incr("stats:page_views")
		client.incrby("stats:api_calls", 5)
		
		page_views = client.get("stats:page_views")
		api_calls = client.get("stats:api_calls")
		puts "Page views: #{page_views}, API calls: #{api_calls}"
		
	ensure
		client.close
	end
end
```

### Binary Data Handling

Redis strings can store any binary data, making them useful for caching images, files, or serialized objects:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Cache serialized data:
		user_data = { id: 123, name: "Alice", preferences: { theme: "dark" } }
		serialized = Marshal.dump(user_data)
		
		client.set("cache:user:123:full", serialized)
		client.expire("cache:user:123:full", 1800)  # 30 minutes
		
		# Retrieve and deserialize:
		cached_data = client.get("cache:user:123:full")
		if cached_data
			deserialized = Marshal.load(cached_data)
			puts "Cached user: #{deserialized}"
		end
		
	rescue => error
		puts "Cache error: #{error.message}"
	ensure
		client.close
	end
end
```

### Expiration and TTL

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Set temporary authentication tokens:
		auth_token = SecureRandom.hex(32)
		client.setex("auth:token:#{auth_token}", 3600, "user:12345")
		
		# Cache with conditional setting:
		cache_key = "cache:expensive_computation"
		unless client.exists(cache_key)
			# Simulate expensive computation:
			result = "computed_result_#{rand(1000)}"
			client.setex(cache_key, 600, result)  # 10 minute cache
			puts "Computed and cached: #{result}"
		else
			cached_result = client.get(cache_key)
			puts "Using cached result: #{cached_result}"
		end
		
		# Check remaining TTL:
		ttl = client.ttl(cache_key)
		puts "Cache expires in #{ttl} seconds"
		
	ensure
		client.close
	end
end
```

## Hashes

Hashes are ideal for caching structured data with multiple fields. They're more memory-efficient than using separate string keys for each field and provide atomic operations on individual fields, making them perfect for temporary storage and caching scenarios.

Perfect for:
- **Session data**: Cache user session attributes and temporary state.
- **Row cache**: Store frequently accessed database rows to reduce query load.
- **Request cache**: Cache computed results from expensive operations or API calls.
- **User preferences**: Store frequently accessed settings that change occasionally.

### Field Operations

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Store session data with individual fields:
		session_id = "session:" + SecureRandom.hex(16)
		client.hset(session_id, "user_id", "12345")
		client.hset(session_id, "username", "alice")
		client.hset(session_id, "roles", "admin,editor")
		client.hset(session_id, "last_activity", Time.now.to_i)
		
		# Set session expiration:
		client.expire(session_id, 3600)  # 1 hour
		
		# Retrieve session fields:
		user_id = client.hget(session_id, "user_id")
		username = client.hget(session_id, "username")
		roles = client.hget(session_id, "roles").split(",")
		
		puts "Session for user #{username} (ID: #{user_id}), roles: #{roles.join(', ')}"
		
		# Check if user has specific role:
		has_admin = client.hexists(session_id, "roles") && 
													client.hget(session_id, "roles").include?("admin")
		puts "Has admin role: #{has_admin}"
		
		# Update last activity timestamp:
		client.hset(session_id, "last_activity", Time.now.to_i)
		
	ensure
		client.close
	end
end
```

### Bulk Operations

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Cache database row with multiple fields:
		user_cache_key = "cache:user:456"
		user_data = {
			"name" => "Bob",
			"email" => "bob@example.com", 
			"last_login" => Time.now.to_i.to_s,
			"status" => "active"
		}
		
		# Set all fields at once:
		client.hmset(user_cache_key, *user_data.to_a.flatten)
		client.expire(user_cache_key, 1800)  # 30 minutes
		
		# Get specific fields:
		name, email = client.hmget(user_cache_key, "name", "email")
		puts "User: #{name} (#{email})"
		
		# Get all cached data:
		all_data = client.hgetall(user_cache_key)
		puts "Full user cache: #{all_data}"
		
		# Get field count:
		field_count = client.hlen(user_cache_key)
		puts "Cached #{field_count} user fields"
		
	ensure
		client.close
	end
end
```

## Lists

Lists maintain insertion order and allow duplicates, making them perfect for implementing queues, activity feeds, or recent item lists. They support efficient operations at both ends.

Essential for:
- **Task queues**: Background job processing with FIFO or LIFO behavior.
- **Activity feeds**: Recent user actions or timeline events.
- **Message queues**: Communication between application components.
- **Recent items**: Keep track of recently viewed or accessed items.

### Queue Operations

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Producer: Add tasks to queue:
		tasks = ["send_email:123", "process_payment:456", "generate_report:789"]
		tasks.each do |task|
			client.lpush("task_queue", task)
			puts "Queued: #{task}"
		end
		
		# Consumer: Process tasks from queue:
		while client.llen("task_queue") > 0
			task = client.rpop("task_queue")
			puts "Processing: #{task}"
			
			# Simulate task processing:
			sleep 0.1
			puts "Completed: #{task}"
		end
		
	ensure
		client.close
	end
end
```

### Recent Items List

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		user_id = "123"
		recent_key = "recent:viewed:#{user_id}"
		
		# User views different pages:
		pages = ["/products/1", "/products/5", "/cart", "/products/1", "/checkout"]
		
		pages.each do |page|
			# Remove if already exists to avoid duplicates:
			client.lrem(recent_key, 0, page)
			
			# Add to front of list:
			client.lpush(recent_key, page)
			
			# Keep only last 5 items:
			client.ltrim(recent_key, 0, 4)
		end
		
		# Get recent items:
		recent_pages = client.lrange(recent_key, 0, -1)
		puts "Recently viewed: #{recent_pages}"
		
		# Set expiration for cleanup:
		client.expire(recent_key, 86400)  # 24 hours
		
	ensure
		client.close
	end
end
```

### Blocking Operations

Blocking operations let consumers wait for new items instead of constantly polling, making them perfect for real-time job processing:

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do |task|
	begin
		# Producer task:
		producer = task.async do
			5.times do |i|
				sleep 1
				job_data = { id: i, action: "process_user_#{i}" }.to_json
				client.lpush("job_queue", job_data)
				puts "Produced job #{i}"
			end
		end
		
		# Consumer task with blocking pop:
		consumer = task.async do
			5.times do
				# Block for up to 2 seconds waiting for work:
				result = client.brpop("job_queue", 2)
				
				if result
					queue_name, job_json = result
					job = JSON.parse(job_json)
					puts "Processing job #{job['id']}: #{job['action']}"
					sleep 0.5  # Simulate work
				else
					puts "No work available, continuing..."
				end
			end
		end
		
		# Wait for both tasks to complete:
		producer.wait
		consumer.wait
		
	ensure
		client.close
	end
end
```

## Sets and Sorted Sets

Sets automatically handle uniqueness and provide fast membership testing, while sorted sets add scoring for rankings and range queries.

Sets are perfect for:
- **Tags and categories**: User interests, product categories.
- **Unique visitors**: Track unique users without duplicates.
- **Permissions**: User roles and access rights.
- **Cache invalidation**: Track which cache keys need updating.

Sorted sets excel at:
- **Leaderboards**: Game scores, user rankings.
- **Time-based data**: Recent events, scheduled tasks.
- **Priority queues**: Tasks with different priorities.
- **Range queries**: Find items within score ranges.

### Set Operations

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Track unique daily visitors:
		today = Date.today.to_s
		visitor_key = "visitors:#{today}"
		
		# Add visitors (duplicates automatically ignored):
		visitors = ["user:123", "user:456", "user:123", "user:789", "user:456"]
		visitors.each do |visitor|
			client.sadd(visitor_key, visitor)
		end
		
		# Get unique visitor count:
		unique_count = client.scard(visitor_key)
		puts "Unique visitors today: #{unique_count}"
		
		# Check if specific user visited:
		visited = client.sismember(visitor_key, "user:123")
		puts "User 123 visited today: #{visited}"
		
		# Get all unique visitors:
		all_visitors = client.smembers(visitor_key)
		puts "All visitors: #{all_visitors}"
		
		# Set expiration for daily cleanup:
		client.expire(visitor_key, 86400)  # 24 hours
		
	ensure
		client.close
	end
end
```

### Scoring and Ranking

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Track user activity scores:
		leaderboard_key = "leaderboard:weekly"
		
		# Add user scores:
		client.zadd(leaderboard_key, 150, "user:alice")
		client.zadd(leaderboard_key, 200, "user:bob") 
		client.zadd(leaderboard_key, 175, "user:charlie")
		client.zadd(leaderboard_key, 125, "user:david")
		
		# Get top 3 users:
		top_users = client.zrevrange(leaderboard_key, 0, 2, with_scores: true)
		puts "Top 3 users this week:"
		top_users.each_slice(2).with_index do |(user, score), index|
			puts "  #{index + 1}. #{user}: #{score.to_i} points"
		end
		
		# Get user's rank and score:
		alice_rank = client.zrevrank(leaderboard_key, "user:alice")
		alice_score = client.zscore(leaderboard_key, "user:alice")
		puts "Alice: rank #{alice_rank + 1}, score #{alice_score.to_i}"
		
		# Update scores:
		client.zincrby(leaderboard_key, 25, "user:alice")
		new_score = client.zscore(leaderboard_key, "user:alice")
		puts "Alice's updated score: #{new_score.to_i}"
		
		# Set weekly expiration:
		client.expire(leaderboard_key, 604800)  # 7 days
		
	ensure
		client.close
	end
end
```

### Time-Based Range Queries

``` ruby
require "async/redis"

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	begin
		# Track user activity with timestamps:
		activity_key = "activity:user:123"
		
		# Add timestamped activities:
		activities = [
			{ action: "login", time: Time.now.to_f - 3600 },
			{ action: "view_page", time: Time.now.to_f - 1800 },
			{ action: "purchase", time: Time.now.to_f - 900 },
			{ action: "logout", time: Time.now.to_f - 300 }
		]
		
		activities.each do |activity|
			client.zadd(activity_key, activity[:time], activity[:action])
		end
		
		# Get activities from last hour:
		one_hour_ago = Time.now.to_f - 3600
		recent_activities = client.zrangebyscore(activity_key, one_hour_ago, "+inf")
		puts "Recent activities: #{recent_activities}"
		
		# Count activities in time range:
		thirty_min_ago = Time.now.to_f - 1800
		recent_count = client.zcount(activity_key, thirty_min_ago, "+inf")
		puts "Activities in last 30 minutes: #{recent_count}"
		
		# Clean up old activities:
		two_hours_ago = Time.now.to_f - 7200
		removed = client.zremrangebyscore(activity_key, "-inf", two_hours_ago)
		puts "Removed #{removed} old activities"
		
	ensure
		client.close
	end
end
```
