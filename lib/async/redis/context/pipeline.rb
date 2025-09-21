# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by David Ortiz.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2022, by Tim Willard.

require_relative "generic"

module Async
	module Redis
		module Context
			# Send multiple commands without waiting for the response, instead of sending them one by one.
			class Pipeline < Generic
				include ::Protocol::Redis::Methods
				
				# A synchronous wrapper for pipeline operations that executes one command at a time.
				class Sync
					include ::Protocol::Redis::Methods
					
					# Initialize a new sync wrapper.
					# @parameter pipeline [Pipeline] The pipeline to wrap.
					def initialize(pipeline)
						@pipeline = pipeline
					end
					
					# This method just accumulates the commands and their params.
					def call(...)
						@pipeline.call(...)
						
						@pipeline.flush(1)
						
						return @pipeline.read_response
					end
				end
				
				# Initialize a new pipeline context.
				# @parameter pool [Pool] The connection pool to use.
				def initialize(pool)
					super(pool)
					
					@count = 0
					@sync = nil
				end
				
				# Flush responses.
				# @parameter count [Integer] leave this many responses.
				def flush(count = 0)
					while @count > count
						read_response
					end
				end
				
				# Collect all pending responses.
				# @yields {...} Optional block to execute while collecting responses.
				# @returns [Array] Array of all responses if no block given.
				def collect
					if block_given?
						flush
						yield
					end
					
					@count.times.map{read_response}
				end
				
				# Get a synchronous wrapper for this pipeline.
				# @returns [Sync] A synchronous wrapper that executes commands immediately.
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
				
				# Read a response from the pipeline.
				# @returns [Object] The next response in the pipeline.
				def read_response
					if @count > 0
						@count -= 1
						super
					else
						raise RuntimeError, "No more responses available!"
					end
				end
				
				# Close the pipeline and flush all pending responses.
				def close
					flush
				ensure
					super
				end
			end
		end
	end
end
