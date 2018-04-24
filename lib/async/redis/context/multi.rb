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

module Async
	module Redis
		module Context
			class BaseContext
				def self.enter(connection, &block)
					context = self.new(connection)
					
					return context unless block_given?
					
					begin
						yield context
					rescue ServerError
						puts "caught server error"
						return context.cleanup
					ensure
						return context.success
					end
				end
				
				def initialize(connection)
					@connection = connection
				end
			end
			
			class Multi < BaseContext
				def initialize(connection)
					super(connection)
					@connection.write_request(['MULTI'])
					@connection.read_response
				end
				
				def set(key, value)
					@connection.write_request(['SET', key, value])
					return @connection.read_response
				end
				
				def get(key)
					@connection.write_request(['GET', key])
					return @connection.read_response
				end
				
				def execute
					@connection.write_request(['EXEC'])
					response = @connection.read_response
					return response
				end
				
				def discard
					@connection.write_request(['DISCARD'])
					return @connection.read_response
				end
				
				alias cleanup discard
				alias success execute
			end
		end
	end 
end
