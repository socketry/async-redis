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
			module Strings
				def append(key, value)
					return call('APPEND', key, value)
				end

				def bitcount(key, *range)
					return call('BITCOUNT', key, *range)
				end

				def decr(key)
					return call('DECR', key)
				end

				def decrby(key, decrement)
					return call('DECRBY', key, decrement)
				end

				def get(key)
					return call('GET', key)
				end

				def getbit(key, offset)
					return call('GETBIT', key, offset)
				end

				def getrange(key, start_index, end_index)
					return call('GETRANGE', key, start_index, end_index)
				end

				def getset(key, value)
					return call('GETSET', key, value)
				end

				def incr(key)
					return call('INCR', key)
				end

				def incrby(key, increment)
					return call('INCRBY', key, increment)
				end

				def incrbyfloat(key, increment)
					return call('INCRBYFLOAT', key, increment)
				end

				def mget(key, *keys)
					return call('MGET', key, *keys)
				end

				def mset(pairs)
					flattened_pairs = pairs.keys.zip(pairs.values).flatten
					return call('MSET', *flattened_pairs)
				end

				def msetnx(pairs)
					flattened_pairs = pairs.keys.zip(pairs.values).flatten
					return call('MSETNX', *flattened_pairs)
				end

				def psetex(key, milliseconds, value)
					return set key, value, milliseconds: milliseconds
				end

				def set(key, value, **options)
					arguments = []

					if options.has_key? :seconds
						arguments << 'EX'
						arguments << options[:seconds]
					end

					if options.has_key? :milliseconds
						arguments << 'PX'
						arguments << options[:milliseconds]
					end

					if options[:condition] == :nx
						arguments << 'NX'
					elsif options[:condition] == :xx
						arguments << 'XX'
					end

					return call('SET', key, value, *arguments)
				end

				def setbit(key, offset, value)
					return call('SETBIT', key, offset, value)
				end

				def setex(key, seconds, value)
					return set key, value, seconds: seconds
				end

				def setnx(key, value)
					return set key, value, condition: :nx
				end

				def setrange(key, offset, value)
					return call('SETRANGE', key, offset, value)
				end

				def strlen(key)
					return call('STRLEN', key)
				end
			end
		end
	end
end
