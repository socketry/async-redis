# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require 'protocol/redis'

module Async
	module Redis
		module Protocol
			module RESP2
				class Connection < ::Protocol::Redis::Connection
					def concurrency
						1
					end
					
					def viable?
						@stream.readable?
					end
					
					def reusable?
						!@stream.closed?
					end
				end
				
				def self.client(stream)
					Connection.new(stream)
				end
			end
		end
	end
end
