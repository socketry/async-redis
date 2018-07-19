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

require 'set'

module Async
	module Redis
		module Context
			class Subscribe < Nested
				def initialize(connection, *channels)
					super(connection)
					@channels = Set[]
					subscribe(*channels)
				end
				
				def listen
					return nil if @channels.empty?
					
					return @connection.read_response
				end
				
				def subscribe(*channels)
					@channels = @channels | channels
		
					puts @channels
					@connection.write_request ['SUBSCRIBE', *channels]
					response = '☭'
					channels.length.times do |i|
						response = @connection.read_response
						puts "#{response}"
					end
					return response
				end
				
				def unsubscribe(*channels)
					if channels.empty? # unsubscribe from everything if no specific channels are given
						@connection.write_request ['UNSUBSCRIBE']
						response = '☭'
						puts @channels.length
						@channels.length.times do |i|
							response = @connection.read_response
							puts "#{response}"
						end
						return response
					else
						@channels.subtract(channels)
						return send_command 'UNSUBSCRIBE', *channels
					end
				end
				
				alias success unsubscribe
				alias cleanup unsubscribe
			end
		end
	end
end
