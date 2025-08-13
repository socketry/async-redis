# frozen_string_literal: true

module Async
	module Redis
		# A map that stores ranges and their associated values for efficient lookup.
		class RangeMap
			# Initialize a new RangeMap.
			def initialize
				@ranges = []
			end
			
			# Add a range-value pair to the map.
			# @parameter range [Range] The range to map.
			# @parameter value [Object] The value to associate with the range.
			# @returns [Object] The added value.
			def add(range, value)
				@ranges << [range, value]
				return value
			end
			
			# Find the value associated with a key within any range.
			# @parameter key [Object] The key to find.
			# @yields {...} Block called if no range contains the key.
			# @returns [Object] The value if found, result of block if given, or nil.
			def find(key)
				@ranges.each do |range, value|
					return value if range.include?(key)
				end
				if block_given?
					return yield
				end
				return nil
			end
			
			# Iterate over all values in the map.
			# @yields {|value| ...} Block called for each value.
			#  @parameter value [Object] The value from the range-value pair.
			def each
				@ranges.each do |range, value|
					yield value
				end
			end
			
			# Get a random value from the map.
			# @returns [Object] A randomly selected value, or nil if map is empty.
			def sample
				return nil if @ranges.empty?
				range, value = @ranges.sample
				return value
			end
			
			# Clear all ranges from the map.
			def clear
				@ranges.clear
			end
		end
	end
end
