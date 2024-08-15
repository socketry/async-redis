# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by David Ortiz.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2022, by Tim Willard.

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
					def call(command, *arguments)
						@pipeline.call(command, *arguments)
						
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
				def call(command, *arguments)
					write_request(command, *arguments)
					
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
				ensure
					super
				end
			end
		end
	end
end
