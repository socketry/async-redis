# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# and Huba Nagy
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

require_relative 'nested'

module Async
	module Redis
		module Context
			class Multi < Nested
				def initialize(connection, connection_pool)
					super(connection, connection_pool)
					@connection.write_request(['MULTI'])
					@connection.read_response
				end
				
				def set(key, value)
					return send_command 'SET', key, value
				end
				
				def get(key)
					return send_command 'GET', key
				end
				
				def execute
					response = send_command 'EXEC'
					@connection_pool.release(@connection)
					return response
				end
				
				def discard
					response = send_command 'DISCARD'
					@connection_pool.release(@connection)
					return response
				end
				
				alias cleanup discard
				alias success execute
			end
		end
	end 
end
