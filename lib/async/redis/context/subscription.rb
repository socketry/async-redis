# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2025, by Samuel Williams.

require_relative "generic"

module Async
	module Redis
		module Context
			# Context for Redis pub/sub subscription operations.
			class Subscription < Generic
				MESSAGE = "message"
				PMESSAGE = "pmessage"
				SMESSAGE = "smessage"
				
				# Initialize a new subscription context.
				# @parameter pool [Pool] The connection pool to use.
				# @parameter channels [Array(String)] The channels to subscribe to.
				def initialize(pool, channels)
					super(pool)
					
					subscribe(channels) if channels.any?
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
						return response if response.first == MESSAGE || response.first == PMESSAGE || response.first == SMESSAGE
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
				
				# Subscribe to channel patterns.
				# @parameter patterns [Array(String)] The channel patterns to subscribe to.
				def psubscribe(patterns)
					@connection.write_request ["PSUBSCRIBE", *patterns]
					@connection.flush
				end
				
				# Unsubscribe from channel patterns.
				# @parameter patterns [Array(String)] The channel patterns to unsubscribe from.
				def punsubscribe(patterns)
					@connection.write_request ["PUNSUBSCRIBE", *patterns]
					@connection.flush
				end
				
				# Subscribe to sharded channels (Redis 7.0+).
				# @parameter channels [Array(String)] The sharded channels to subscribe to.
				def ssubscribe(channels)
					@connection.write_request ["SSUBSCRIBE", *channels]
					@connection.flush
				end
				
				# Unsubscribe from sharded channels (Redis 7.0+).
				# @parameter channels [Array(String)] The sharded channels to unsubscribe from.
				def sunsubscribe(channels)
					@connection.write_request ["SUNSUBSCRIBE", *channels]
					@connection.flush
				end
			end
		end
	end
end
