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

# DO NOT manually edit this file it was generated based on https://raw.githubusercontent.com/antirez/redis-doc/master/commands.json.

module Async
	module Redis
		module Methods
			module AutoGenerated
				module Strings
					def append(*arguments)
						return call('APPEND', arguments)
					end

					def bitcount(*arguments)
						return call('BITCOUNT', arguments)
					end

					def bitfield(*arguments)
						return call('BITFIELD', arguments)
					end

					def bitop(*arguments)
						return call('BITOP', arguments)
					end

					def bitpos(*arguments)
						return call('BITPOS', arguments)
					end

					def decr(*arguments)
						return call('DECR', arguments)
					end

					def decrby(*arguments)
						return call('DECRBY', arguments)
					end

					def get(*arguments)
						return call('GET', arguments)
					end

					def getbit(*arguments)
						return call('GETBIT', arguments)
					end

					def getrange(*arguments)
						return call('GETRANGE', arguments)
					end

					def getset(*arguments)
						return call('GETSET', arguments)
					end

					def incr(*arguments)
						return call('INCR', arguments)
					end

					def incrby(*arguments)
						return call('INCRBY', arguments)
					end

					def incrbyfloat(*arguments)
						return call('INCRBYFLOAT', arguments)
					end

					def mget(*arguments)
						return call('MGET', arguments)
					end

					def mset(*arguments)
						return call('MSET', arguments)
					end

					def msetnx(*arguments)
						return call('MSETNX', arguments)
					end

					def psetex(*arguments)
						return call('PSETEX', arguments)
					end

					def set(*arguments)
						return call('SET', arguments)
					end

					def setbit(*arguments)
						return call('SETBIT', arguments)
					end

					def setex(*arguments)
						return call('SETEX', arguments)
					end

					def setnx(*arguments)
						return call('SETNX', arguments)
					end

					def setrange(*arguments)
						return call('SETRANGE', arguments)
					end

					def strlen(*arguments)
						return call('STRLEN', arguments)
					end

				end
			end
		end
	end
end
