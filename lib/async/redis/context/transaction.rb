# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2023, by Samuel Williams.

require_relative "pipeline"

module Async
	module Redis
		module Context
			class Transaction < Pipeline
				def initialize(pool, *arguments)
					super(pool)
				end
				
				def multi
					call("MULTI")
				end
				
				def watch(*keys)
					sync.call("WATCH", *keys)
				end
				
				# Execute all queued commands, provided that no watched keys have been modified. It's important to note that even when a command fails, all the other commands in the queue are processed – Redis will not stop the processing of commands.
				def execute
					sync.call("EXEC")
				end
				
				def discard
					sync.call("DISCARD")
				end
			end
		end
	end 
end
