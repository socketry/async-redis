# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

def client
	require "irb"
	require "async/redis/client"
	
	endpoint = Async::Redis.local_endpoint
	client = Async::Redis::Client.new(endpoint)
	
	Async do
		binding.irb
	end
end

# Update the project documentation with the new version number.
#
# @parameter version [String] The new version number.
def after_gem_release_version_increment(version)
	context["releases:update"].call(version)
	context["utopia:project:readme:update"].call
end
