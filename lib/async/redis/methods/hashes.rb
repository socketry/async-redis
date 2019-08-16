# Copyright, 2019, by Mikael Henriksson. <http://www.mhenrixon.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Async
	module Redis
		module Methods
			module Hashes
				def hlen(key)
					return call('HLEN', key)
				end
				
				def hset(key, field, value)
					return call('HSET', key, field, value)
				end
				
				def hsetnx(key, field, value)
					return call('HSETNX', key, field, value)
				end
				
				def hmset(key, *attrs)
					return call('HMSET', key, *attrs)
				end
				
				def hget(key, field)
					return call('HGET', key, field)
				end
				
				def hmget(key, *fields, &blk)
					return call('HMGET', key, *fields, &blk)
				end
				
				def hdel(key, *fields)
					return call('HDEL', key, *fields)
				end
				
				def hexists(key, field)
					return call('HEXISTS', key, field)
				end
				
				def hincrby(key, field, increment)
					return call('HINCRBY', key, field, increment)
				end
				
				def hincrbyfloat(key, field, increment)
					return call('HINCRBYFLOAT', key, field, increment)
				end
				
				def hkeys(key)
					return call('HKEYS', key)
				end
				
				def hvals(key)
					return call('HVALS', key)
				end
				
				def hgetall(key)
					return call('HGETALL', key)
				end
			end
		end
	end
end
