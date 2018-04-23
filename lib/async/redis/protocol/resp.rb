# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/io/protocol/line'

module Async
	module Redis
		module Protocol
			# Implements basic HTTP/1.1 request/response.
			class RESP < Async::IO::Protocol::Line
				CRLF = "\r\n".freeze
				
				def initialize(stream)
					super(stream, CRLF)
				end
				
				def write_command(arguments)
					write_lines("*#{arguments.count}")
					arguments.each(&self.method(:write_object))
					write_lines
					@stream.flush
				end
				
				def write_object(object)
					case object
					when String
						write_lines("$#{object.bytesize}", object)
					when Array
						write_lines("*#{object.count}")
						object.each(&self.method(:write_object))
					else
						write_object(object.to_redis)
					end
				end
				
				def read_object
					token = @stream.read(1)
					
					case token
					when '$'
						buffer = read_line
						length = buffer.to_i
						buffer = @stream.read(length)
						read_line # Eat trailing whitespace?
						
						return buffer
					else
						raise NotImplementedError("Implementation for token #{token} missing")
					end
				end
			end
		end
	end
end
