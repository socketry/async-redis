# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# Copyright, 2019, by Huba Nagy.
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
			# Send multiple commands without waiting for the response, instead of sending them one by one.
			class Pipeline < Generic
				include ::Protocol::Redis::Methods
				
				class Sync
					include ::Protocol::Redis::Methods
					
					def initialize(pipeline)
						@pipeline = pipeline
					end
					
					# This method just accumulates the commands and their params.
					def call(command, *args)
						@pipeline.call(command, *args)
						
						@pipeline.flush(1)
						
						return @pipeline.read_response
					end
				end
				
				def initialize(pool)
					super(pool)
					
					@count = 0
					@sync = nil
				end
				
				# Flush responses.
				# @param count [Integer] leave this many responses.
				def flush(count = 0)
					while @count > count
						read_response
					end
				end
				
				def sync
					@sync ||= Sync.new(self)
				end
				
				# This method just accumulates the commands and their params.
				def write_request(*)
					super
					
					@count += 1
				end
				
				# This method just accumulates the commands and their params.
				def call(command, *args)
					write_request(command, *args)
					
					return nil
				end
				
				def read_response
					if @count > 0
						@count -= 1
						super
					else
						raise RuntimeError, "No more responses available!"
					end
				end
				
				def collect
					yield
					
					@count.times.map{read_response}
				end
				
				def close
					flush
					
					super
				end
			end
		end
	end
end
