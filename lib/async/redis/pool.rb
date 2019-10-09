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

require 'async/notification'

module Async
	module Redis
		# It might make sense to add support for pipelining https://redis.io/topics/pipelining
		# We should be able to wrap the protocol so that write_request and read_response happen in lockstep.
		# The only problem would be blocking operations. It might also be confusing if order of operations affects commands.
		class Pool
			def initialize(limit = nil, &block)
				@resources = []
				@available = Async::Notification.new
				
				@limit = limit
				@active = 0
				
				@constructor = block
			end
			
			attr :resources
			
			def empty?
				@resources.empty?
			end
			
			def acquire
				resource = wait_for_resource
				
				return resource unless block_given?
				
				begin
					yield resource
				ensure
					release(resource)
				end
			end
			
			# Make the resource resources and let waiting tasks know that there is something resources.
			def release(resource)
				# A resource that is not good should also not be reusable.
				unless resource.closed?
					reuse(resource)
				else
					retire(resource)
				end
			end
			
			def close
				@resources.each(&:close)
				@resources.clear
				
				@active = 0
			end
			
			def to_s
				"\#<#{self.class} resources=#{resources.size} limit=#{@limit}>"
			end
			
			protected
			
			def reuse(resource)
				Async.logger.debug(self) {"Reuse #{resource}"}
				
				@resources << resource
				
				@available.signal
			end
			
			def retire(resource)
				Async.logger.debug(self) {"Retire #{resource}"}
				
				@active -= 1
				
				resource.close
				
				@available.signal
			end
			
			def wait_for_resource
				# If we fail to create a resource (below), we will end up waiting for one to become resources.
				until resource = available_resource
					@available.wait
				end
				
				Async.logger.debug(self) {"Wait for resource #{resource}"}
				
				return resource
			end
			
			def create
				# This might return nil, which means creating the resource failed.
				return @constructor.call
			end
			
			def available_resource
				while resource = @resources.pop
					return resource if resource.connected?
				end
				
				if !@limit or @active < @limit
					Async.logger.debug(self) {"No resources resources, allocating new one..."}
					
					@active += 1
					
					return create
				end
				
				return nil
			end
		end
	end
end
