# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'async/redis'
require 'async/redis/client'
require 'async/redis/key'

require 'sus/fixtures/async'

require 'securerandom'

ClientContext = Sus::Shared("client context") do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {@client = Async::Redis::Client.new(endpoint)}
	
	let(:root) {Async::Redis::Key["async-redis:test:#{SecureRandom.uuid}"]}
	
	def before
		super
		keys = client.keys("#{root}:*")
		client.del(*keys) if keys.any?
	end
	
	def after
		@client&.close
		super
	end
end
