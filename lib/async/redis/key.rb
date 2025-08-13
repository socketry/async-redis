# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

module Async
	module Redis
		# Represents a Redis key with utility methods for key manipulation.
		class Key
			# Create a new Key instance.
			# @parameter path [String] The key path.
			# @returns [Key] A new Key instance.
			def self.[] path
				self.new(path)
			end
			
			include Comparable
			
			# Initialize a new Key.
			# @parameter path [String] The key path.
			def initialize(path)
				@path = path
			end
			
			# Get the byte size of the key.
			# @returns [Integer] The byte size of the key path.
			def size
				@path.bytesize
			end
			
			attr :path
			
			# Convert the key to a string.
			# @returns [String] The key path as a string.
			def to_s
				@path
			end
			
			# Convert the key to a string (for String compatibility).
			# @returns [String] The key path as a string.
			def to_str
				@path
			end
			
			# Create a child key by appending a subkey.
			# @parameter key [String] The subkey to append.
			# @returns [Key] A new Key with the appended subkey.
			def [] key
				self.class.new("#{@path}:#{key}")
			end
			
			# Compare this key with another key.
			# @parameter other [Key] The other key to compare with.
			# @returns [Integer] -1, 0, or 1 for comparison result.
			def <=> other
				@path <=> other.to_str
			end
		end
	end
end
