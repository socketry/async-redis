# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2024, by Samuel Williams.

require_relative "generic"

module Async
	module Redis
		module Context
			class Subscribe < Generic
				MESSAGE = "message"
				
				def initialize(pool, channels)
					super(pool)
					
					subscribe(channels)
				end
				
				def close
					# There is no way to reset subscription state. On Redis v6+ you can use RESET, but this is not supported in <= v6.
					@connection&.close
					
					super
				end
				
				def listen
					while response = @connection.read_response
						return response if response.first == MESSAGE
					end
				end
				
				def each
					return to_enum unless block_given?
					
					while response = self.listen
						yield response
					end
				end
				
				def subscribe(channels)
					@connection.write_request ["SUBSCRIBE", *channels]
					@connection.flush
				end
				
				def unsubscribe(channels)
					@connection.write_request ["UNSUBSCRIBE", *channels]
					@connection.flush
				end
			end
		end
	end
end
