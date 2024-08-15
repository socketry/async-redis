# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'protocol/redis'

module Async
	module Redis
		module Protocol
			# Executes AUTH after the user has established a connection.
			class Selected
				# Authentication has failed for some reason.
				class SelectionError < StandardError
				end
				
				# Create a new authenticated protocol.
				#
				# @parameter index [Integer] The database index to select.
				# @parameter protocol [Object] The delegated protocol for connecting.
				def initialize(index, protocol: Async::Redis::Protocol::RESP2)
					@index = index
					@protocol = protocol
				end
				
				# Create a new client and authenticate it.
				def client(stream)
					client = @protocol.client(stream)
					
					client.write_request(["SELECT", @index])
					response = client.read_response
					
					if response != "OK"
						raise SelectionError, "Could not select database: #{response}"
					end
					
					return client
				end
			end
		end
	end
end
