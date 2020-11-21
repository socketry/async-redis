# frozen_string_literal: true

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

require_relative 'generic'

module Async
	module Redis
		module Context
			class Subscribe < Generic
				MESSAGE = 'message'
				
				def initialize(pool, channels)
					super(pool)
					
					subscribe(channels)
				end
				
				def close
					# There is no way to reset subscription state. On Redis v6+ you can use RESET, but this is not supported in <= v6.
					@connection&.close
					
					super
				end
				
				def listen
					while response = @connection.read_response
						return response if response.first == MESSAGE
					end
				end
				
				def subscribe(channels)
					@connection.write_request ['SUBSCRIBE', *channels]
					@connection.flush
				end
				
				def unsubscribe(channels)
					@connection.write_request ['UNSUBSCRIBE', *channels]
					@connection.flush
				end
			end
		end
	end
end
