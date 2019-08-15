# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
		class ServerError < StandardError
		end
		
		module Protocol
			CRLF = "\r\n".freeze
			
			class RESP < Async::IO::Protocol::Line
				class << self
					alias client new
				end
				
				def initialize(stream)
					super(stream, CRLF)
				end
				
				def closed?
					@stream.closed?
				end
				
				# The redis server doesn't want actual objects (e.g. integers) but only bulk strings. So, we inline it for performance.
				def write_request(arguments, flush: true)
					write_lines("*#{arguments.size}")

					arguments.each do |argument|
						string = argument.to_s

						write_lines("$#{string.bytesize}", string)
					end

					@stream.flush if flush
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
				
				def read_data(length)
					buffer = @stream.read(length) or @stream.eof!
					
					# Eat trailing whitespace because length does not include the CRLF:
					@stream.read(2) or @stream.eof!
					
					return buffer
				end
				
				def read_object
					line = read_line
					token = line.slice!(0, 1)
					
					case token
					when '$'
						length = line.to_i
						
						if length == -1
							return nil
						else
							return read_data(length)
						end
					when '*'
						count = line.to_i
						
						# Null array (https://redis.io/topics/protocol#resp-arrays):
						return nil if count == -1
						
						array = Array.new(count) {read_object}
						
						return array
					when ':'
						return line.to_i
					
					when '-'
						raise ServerError.new(line)
					
					when '+'
						return line
					
					else
						@stream.flush
						
						raise NotImplementedError, "Implementation for token #{token} missing"
					end
					
					# TODO: If an exception (e.g. Async::TimeoutError) propagates out of this function, perhaps @stream should be closed? Otherwise it might be in a weird state.
				end
				
				alias read_response read_object

				def write_pipeline(commands)
					commands.each do |command|
						write_request(command, flush: false)
					end

					@stream.flush
				end

				private

				# Override Async::IO::Protocol::Line#write_line
				# The original method performs a flush. This one does not and moves the
				# responsibility of flushing to the caller of the method.
				# In the case of Redis, we do not want to perform a flush in every line,
				# because each Redis command contains several lines. Flushing once per
				# command is more efficient because it avoids unnecessary writes to the
				# socket.
				def write_lines(*args)
					if args.empty?
						@stream.write(@eol)
					else
						args.each do |arg|
							@stream.write(arg)
							@stream.write(@eol)
						end
					end
				end
			end
		end
	end
end
