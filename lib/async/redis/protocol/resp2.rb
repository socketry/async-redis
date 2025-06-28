# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require "protocol/redis"

module Async
	module Redis
		# @namespace
		module Protocol
			# RESP2 protocol implementation for Redis.
			module RESP2
				# A connection implementation for RESP2 protocol.
				class Connection < ::Protocol::Redis::Connection
					# Get the concurrency level for this connection.
					# @returns [Integer] The concurrency level (1 for RESP2).
					def concurrency
						1
					end
					
					# Check if the connection is viable for use.
					# @returns [Boolean] True if the stream is readable.
					def viable?
						@stream.readable?
					end
					
					# Check if the connection can be reused.
					# @returns [Boolean] True if the stream is not closed.
					def reusable?
						!@stream.closed?
					end
				end
				
				# Create a new RESP2 client connection.
				# @parameter stream [IO] The stream to use for communication.
				# @returns [Connection] A new RESP2 connection.
				def self.client(stream)
					Connection.new(stream)
				end
			end
		end
	end
end
