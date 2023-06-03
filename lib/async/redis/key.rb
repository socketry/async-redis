# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

module Async
	module Redis
		class Key
			def self.[] path
				self.new(path)
			end
			
			include Comparable
			
			def initialize(path)
				@path = path
			end
			
			def size
				@path.bytesize
			end
			
			attr :path
			
			def to_s
				@path
			end
			
			def to_str
				@path
			end
			
			def [] key
				self.class.new("#{@path}:#{key}")
			end
			
			def <=> other
				@path <=> other.to_str
			end
		end
	end
end
