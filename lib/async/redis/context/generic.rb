# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by Mikael Henriksson.
# Copyright, 2019-2025, by Samuel Williams.

require "protocol/redis/methods"

module Async
	module Redis
		# @namespace
		module Context
			# Base class for Redis command execution contexts.
			class Generic
				# Initialize a new generic context.
				# @parameter pool [Pool] The connection pool to use.
				# @parameter arguments [Array] Additional arguments for the context.
				def initialize(pool, *arguments)
					@pool = pool
					@connection = pool.acquire
				end
				
				# Close the context and release the connection back to the pool.
				def close
					if connection = @connection
						@connection = nil
						@pool.release(connection)
					end
				end
				
				# Write a Redis command request to the connection.
				# @parameter command [String] The Redis command.
				# @parameter arguments [Array] The command arguments.
				def write_request(command, *arguments)
					@connection.write_request([command, *arguments])
				end
				
				# Read a response from the Redis connection.
				# @returns [Object] The Redis response.
				def read_response
					@connection.flush
					
					return @connection.read_response
				end
				
				# Execute a Redis command and return the response.
				# @parameter command [String] The Redis command.
				# @parameter arguments [Array] The command arguments.
				# @returns [Object] The Redis response.
				def call(command, *arguments)
					write_request(command, *arguments)
					
					return read_response
				end
			end
		end
	end
end
