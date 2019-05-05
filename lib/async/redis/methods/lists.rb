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

module Async
	module Redis
		module Methods
			module Lists
				def blpop(*keys, timeout: 0)
					return call('BLPOP', *keys, timeout)
				end

				def brpop(*keys, timeout: 0)
					return call('BRPOP', *keys, timeout)
				end

				def brpoplpush(source, destination, timeout)
					return call('BRPOPLPUSH', source, destination, timeout)
				end

				def lindex(key, index)
					return call('LINDEX', key, index)
				end

				def linsert(key, position=:before, index, value)
					if position == :before
						offset = 'BEFORE'
					else
						offset = 'AFTER'
					end

					return call('LINSERT', key, offset, index, value)
				end

				def llen(key)
					return call('LLEN', key)
				end

				def lpop(key)
					return call('LPOP', key)
				end

				def lpush(key, value, *values)
					case value
					when Array
						values = value
					else
						values = [value] + values
					end

					return call('LPUSH', key, *values)
				end

				def lpushx(key, value)
					return call('LPUSHX', key, value)
				end

				def lrange(key, start, stop)
					return call('LRANGE', key, start, stop)
				end

				def lrem(key, count, value)
					return call('LREM', key, count)
				end

				def lset(key, index, values)
					return call('LSET', key, index, values)
				end

				def ltrim(key, start, stop)
					return call('LTRIM', key, start, stop)
				end

				def rpop(key)
					return call('RPOP', key)
				end

				def rpoplpush(source, destination=nil)
					destination = source if destination.nil?

					return call('RPOPLPUSH', source, destination)
				end

				def rpush(key, value, *values)
					case value
					when Array
						values = value
					else
						values = [value] + values
					end

					return call('RPUSH', key, *values)
				end

				def rpushx(key, value)
					return call('RPUSHX', key, value)
				end
			end
		end
	end
end
