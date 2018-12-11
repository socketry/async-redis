# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# Copyright, 2018, by Huba Nagy.
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

require 'date'

module Async
	module Redis
		module Methods
			module Keys
				def del(key, *keys)
					return call('DEL', key, *keys)
				end

				def dump(key)
					return call('DUMP', key)
				end

				def exists(key, *keys)
					return call('EXISTS', key, *keys)
				end

				def expire(key, seconds)
					return call('EXPIRE', key, seconds)
				end

				def expireat(key, time)
					case time
					when DateTime, Time, Date 
						timestamp =  time.strftime('%s').to_i
					else
						timestamp = time
					end

					return call('EXPIREAT', key, timestamp)
				end

				def keys(pattern)
					return call('KEYS', pattern)
				end

				def migrate

				end

				def move(key, db)
					return call('MOVE', key, db)
				end

				def object

				end

				def persist(key)
					return call('PERSIST', key)
				end

				def pexpire(key, milliseconds)
					return call('PEXPIRE', milliseconds)
				end

				def pexpireat(key, time)
					case time.class
					when DateTime, Time, Date 
						timestamp =  time.strftime('%Q').to_i
					else
						timestamp = time
					end
					
					return call('PEXPIREAT', key, timestamp)
				end

				def pttl(key)
					return call('PTTL', key)
				end

				def randomkey
					return call('RANDOMKEY')
				end

				def rename(key, new_key)
					return call('RENAME', key, new_key)
				end

				def renamenx(key, new_key)
					return call('RENAMENX', key, new_key)
				end

				def restore(key, serialized_value, ttl=0)
					return call('RESTORE', key, ttl, serialized_value)
				end

				def sort

				end

				def touch(key, *keys)
					return call('TOUCH', key, *keys)
				end

				def ttl(key)
					return call('TTL', key)
				end

				def type(key)
					return call('TYPE', key)
				end

				def unlink(key)
					return call('UNLINK', key)
				end
				
				def wait(newreplicas, timeout)

				end

				def scan

				end
			end
		end
	end
end
