# Async::Redis

An asynchronous client for Redis including TLS. Support for streaming requests and responses. Built on top of [async] and [async-io].

[![Build Status](https://secure.travis-ci.org/socketry/async-redis.svg)](https://travis-ci.org/socketry/async-redis)
[![Code Climate](https://codeclimate.com/github/socketry/async-redis.svg)](https://codeclimate.com/github/socketry/async-redis)
[![Coverage Status](https://coveralls.io/repos/socketry/async-redis/badge.svg)](https://coveralls.io/r/socketry/async-redis)

[async]: https://github.com/socketry/async
[async-io]: https://github.com/socketry/async-io

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'async-redis'
```

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install async-redis

## Usage

### Basic Local Connection

```ruby
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	pp client.info
ensure
	client.close
end
```

### Variables

```ruby
require 'async'
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do
	client.set('X', 10)
	pp client.get('X')
ensure
	client.close
end
```

### Subscriptions

```ruby
require 'async'
require 'async/redis'

endpoint = Async::Redis.local_endpoint
client = Async::Redis::Client.new(endpoint)

Async do |task|
	condition = Async::Condition.new
	
	publisher = task.async do
		condition.wait
		
		client.publish 'status.frontend', 'good'
	end
	
	subscriber = task.async do
		client.subscribe 'status.frontend' do |context|
			condition.signal # We are waiting for messages.
			
			type, name, message = context.listen
			
			pp type, name, message
		end
	end
ensure
	client.close
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2018, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).  
Copyright, 2018, by Huba Z. Nagy.  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
