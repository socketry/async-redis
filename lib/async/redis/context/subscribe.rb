# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2025, by Samuel Williams.

require_relative "generic"

module Async
	module Redis
		module Context
			# Context for Redis pub/sub subscription operations.
			class Subscribe < Generic
				MESSAGE = "message"
				
				# Initialize a new subscription context.
				# @parameter pool [Pool] The connection pool to use.
				# @parameter channels [Array(String)] The channels to subscribe to.
				def initialize(pool, channels)
					super(pool)
					
					subscribe(channels)
				end
				
				# Close the subscription context.
				def close
					# There is no way to reset subscription state. On Redis v6+ you can use RESET, but this is not supported in <= v6.
					@connection&.close
					
					super
				end
				
				# Listen for the next message from subscribed channels.
				# @returns [Array] The next message response, or nil if connection closed.
				def listen
					while response = @connection.read_response
						return response if response.first == MESSAGE
					end
				end
				
				# Iterate over all messages from subscribed channels.
				# @yields {|response| ...} Block called for each message.
				# 	@parameter response [Array] The message response.
				def each
					return to_enum unless block_given?
					
					while response = self.listen
						yield response
					end
				end
				
				# Subscribe to additional channels.
				# @parameter channels [Array(String)] The channels to subscribe to.
				def subscribe(channels)
					@connection.write_request ["SUBSCRIBE", *channels]
					@connection.flush
				end
				
				# Unsubscribe from channels.
				# @parameter channels [Array(String)] The channels to unsubscribe from.
				def unsubscribe(channels)
					@connection.write_request ["UNSUBSCRIBE", *channels]
					@connection.flush
				end
			end
		end
	end
end
