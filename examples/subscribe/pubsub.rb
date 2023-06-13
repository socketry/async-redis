#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require_relative '../../lib/async/redis'

class Subscription
	def initialize(topic, endpoint = Async::Redis.local_endpoint)
		@topic = topic
		@endpoint = endpoint
		@client = nil
	end
	
	def client
		@client ||= Async::Redis::Client.new(@endpoint)
	end

	def subscribe
		client.subscribe(@topic) do |context|
			while event = context.listen
				yield event
			end
		end
	end

	def publish(message)
		client.publish @topic, message
	end
end

Sync do |task|
	subscription = Subscription.new("my-topic")
	
	subscriber = task.async do
		subscription.subscribe do |message|
			pp message
		end
	end
	
	10.times do |i|
		subscription.publish("Hello World #{i}")
	end
	
	subscriber.stop
end
