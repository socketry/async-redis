# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Async
	module Redis
		# A map that associates one or more ranges with a value for efficient lookup.
		class RangeMap
			# Initialize a new RangeMap.
			def initialize
				@entries = []
			end
			
			# Add one or more ranges associated with a value to the map.
			# @parameter ranges [Range | Array(Range)] The ranges to map.
			# @parameter value [Object] The value to associate with the ranges.
			# @returns [Object] The added value.
			def add(ranges, value)
				ranges = [ranges] if ranges.is_a?(Range)
				@entries << [ranges, value]
				return value
			end
			
			# Find the value associated with a key within any range.
			# @parameter key [Object] The key to find.
			# @yields {...} Block called if no range contains the key.
			# @returns [Object] The value if found, result of block if given, or nil.
			def find(key)
				@entries.each do |ranges, value|
					return value if ranges.any?{|range| range.include?(key)}
				end
				if block_given?
					return yield
				end
				return nil
			end
			
			# Iterate over each mapped value.
			# @yields {|value| ...} Block called for each value.
			#  @parameter value [Object] The value associated with one or more ranges.
			def each
				@entries.each do |_, value|
					yield value
				end
			end
			
			# Get a random value from the map.
			# @returns [Object] A randomly selected value, or nil if map is empty.
			def sample
				return nil if @entries.empty?
				_, value = @entries.sample
				return value
			end
			
			# Clear all ranges from the map.
			def clear
				@entries.clear
			end
		end
	end
end
