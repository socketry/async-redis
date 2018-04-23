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
		class Error < StandardError
		end
		
		module Protocol
			class RESP < Async::IO::Protocol::Line
				CRLF = "\r\n".freeze
				
				class << self
					alias client new
				end
				
				def initialize(stream)
					super(stream, CRLF)
				end
				
				# The redis server doesn't want actual objects (e.g. integers) but only bulk strings. So, we inline it for performance.
				def write_request(arguments)
					write_lines("*#{arguments.count}")
					
					arguments.each do |argument|
						string = argument.to_s
						
						write_lines("$#{string.bytesize}", string)
					end
					
					@stream.flush
				end
				
				def write_object(object)
					case object
					when String
						write_lines("$#{object.bytesize}", object)
					when Array
						write_array(object)
					when Integer
						write_lines(":#{object}")
					else
						write_object(object.to_redis)
					end
				end
				
				# def write_lines(*args)
				# 	puts "write_lines(#{args.inspect})"
				# 	super
				# end
				# 
				# def read_line
				# 	result = super
				# 	puts "read_line #{result}"
				# 
				# 	return result
				# end
				
				def read_object
					token = @stream.read(1)
					# puts "token: #{token}"
					
					case token
					when '$'
						length = read_line.to_i
						
						if length == -1
							return nil
						else
							buffer = @stream.read(length)
							read_line # Eat trailing whitespace?
						
							return buffer
						end
					when '*'
						count = read_line.to_i
						array = Array.new(count) {read_object}
						
						return array
					when ':'
						return read_line.to_i
					
					when '-'
						raise Error.new(read_line)
					
					when '+'
						return read_line
					
					else
						raise NotImplementedError, "Implementation for token #{token} missing"
					end
				end
				
				alias read_response read_object
			end
		end
	end
end
