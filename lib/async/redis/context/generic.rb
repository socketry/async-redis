# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by Mikael Henriksson.
# Copyright, 2019-2025, by Samuel Williams.

require "protocol/redis/methods"

module Async
	module Redis
		module Context
			class Generic
				def initialize(pool, *arguments)
					@pool = pool
					@connection = pool.acquire
				end
				
				def close
					if @connection
						@pool.release(@connection)
						@connection = nil
					end
				end
				
				def write_request(command, *arguments)
					@connection.write_request([command, *arguments])
				end
				
				def read_response
					@connection.flush
					
					return @connection.read_response
				end
				
				def call(command, *arguments)
					write_request(command, *arguments)
					
					return read_response
				end
			end
		end
	end
end
