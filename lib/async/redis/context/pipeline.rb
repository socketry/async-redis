module Async
	module Redis
		module Context

			# This class accumulates commands and sends several of them in a single
			# request, instead of sending them one by one.
			class Pipeline < Nested

				def initialize(connection_pool)
					super(connection_pool)

					# Each command is an array where the first element is the name of the
					# command ('SET', 'GET', etc.) and the rest of elements are the
					# parameters for that command.
					# Ex: ['SET', 'some_key', 42].
					@commands = []
				end

				# This method just accumulates the commands and their params.
				def call(*args)
					@commands << args
				end

				# Send to redis all the accumulated commands.
				# Returns an array with the result for each command in the same order
				# that they were added with .call().
				def run
					@connection.write_pipeline(@commands)

					result = @commands.size.times.map { @connection.read_response }

					@commands = []

					result
				end
			end
		end
	end
end
