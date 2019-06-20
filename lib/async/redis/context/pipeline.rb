module Async
	module Redis
		module Context

			# This class accumulates commands and sends several of them in a single
			# request, instead of sending them one by one.
			class Pipeline < Nested
				include Methods::Strings
				include Methods::Keys
				include Methods::Lists
				
				def initialize(pool)
					super(pool)
					@command_counter = 0
				end

				def call(command, *args)
					@connection.write_request([command, *args], flush=false)
					@command_counter += 1
				end

				# Send to redis all the accumulated commands.
				# Returns an array with the result for each command in the same order
				# that they were added with .call().
				def run
					@connection.flush

					responses = @command_counter.times.map { @connection.read_object }
					@command_counter = 0
					return responses
				end

				alias :dispatch :run

				def close
					run

					if @connection
						@pool.release(@connection)
						@connection = nil
					end
				end
			end
		end
	end
end
