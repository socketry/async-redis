# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require "async/redis/client"
require "sus/fixtures/async"
require "securerandom"

describe Async::Redis::Context::Subscription do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	
	let(:channel_root) {"async-redis:test:#{SecureRandom.uuid}"}
	let(:news_channel) {"#{channel_root}:news"}
	let(:weather_channel) {"#{channel_root}:weather"}
	let(:sport_channel) {"#{channel_root}:sport"}
	let(:channels) {[news_channel, weather_channel, sport_channel]}
	
	it "should subscribe to channels and report incoming messages" do
		condition = Async::Condition.new
		
		publisher = reactor.async do
			condition.wait
			Console.logger.debug("Publishing message...")
			client.publish(news_channel, "AAA")
		end
		
		listener = reactor.async do
			Console.logger.debug("Subscribing...")
			client.subscribe(*channels) do |context|
				Console.logger.debug("Waiting for message...")
				condition.signal
				
				type, name, message = context.listen
				
				Console.logger.debug("Got: #{type} #{name} #{message}")
				expect(type).to be == "message"
				expect(name).to be == news_channel
				expect(message).to be == "AAA"
			end
		end
		
		publisher.wait
		listener.wait
		
		# At this point, we should check if the client is still working. i.e. we don't leak the state of the subscriptions:
		
		expect(client.info).to be_a(Hash)
		
		client.close
	end
	
	it "can add subscriptions" do
		subscription = client.subscribe(news_channel)
		
		listener = reactor.async do
			type, name, message = subscription.listen
			expect(message).to be == "Sunny"
		end
		
		subscription.subscribe([weather_channel])
		client.publish(weather_channel, "Sunny")
		
		listener.wait
	ensure
		subscription.close
	end
	
	with "#each" do
		it "should iterate over messages" do
			subscription = client.subscribe(news_channel)
			
			listener = reactor.async do
				subscription.each do |type, name, message|
					expect(type).to be == "message"
					expect(name).to be == news_channel
					expect(message).to be == "Hello"
					
					break
				end
			end
			
			client.publish(news_channel, "Hello")
			
			listener.wait
		ensure
			subscription.close
		end
	end
end
