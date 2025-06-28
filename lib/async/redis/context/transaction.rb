# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2025, by Samuel Williams.

require_relative "pipeline"

module Async
	module Redis
		module Context
			# Context for Redis transaction operations using MULTI/EXEC.
			class Transaction < Pipeline
				# Initialize a new transaction context.
				# @parameter pool [Pool] The connection pool to use.
				# @parameter arguments [Array] Additional arguments for the transaction.
				def initialize(pool, *arguments)
					super(pool)
				end
				
				# Begin a transaction block.
				def multi
					call("MULTI")
				end
				
				# Watch keys for changes during the transaction.
				# @parameter keys [Array(String)] The keys to watch.
				def watch(*keys)
					sync.call("WATCH", *keys)
				end
				
				# Execute all queued commands, provided that no watched keys have been modified. It's important to note that even when a command fails, all the other commands in the queue are processed – Redis will not stop the processing of commands.
				def execute
					sync.call("EXEC")
				end
				
				# Discard all queued commands in the transaction.
				def discard
					sync.call("DISCARD")
				end
			end
		end
	end 
end
