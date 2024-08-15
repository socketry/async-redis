# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'protocol/redis'

module Async
	module Redis
		module Protocol
			# Executes AUTH after the user has established a connection.
			class Authenticated
				# Authentication has failed for some reason.
				class AuthenticationError < StandardError
				end
				
				# Create a new authenticated protocol.
				#
				# @parameter credentials [Array] The credentials to use for authentication.
				# @parameter protocol [Object] The delegated protocol for connecting.
				def initialize(credentials, protocol = Async::Redis::Protocol::RESP2)
					@credentials = credentials
					@protocol = protocol
				end
				
				# Create a new client and authenticate it.
				def client(stream)
					client = @protocol.client(stream)
					
					client.write_request(["AUTH", *@credentials])
					response = client.read_response
					
					if response != "OK"
						raise AuthenticationError, "Could not authenticate: #{response}"
					end
					
					return client
				end
			end
		end
	end
end
