# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'async/redis/client'
require 'sus/fixtures/async'

describe Async::Redis::Context::Subscribe do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	
	it "should subscribe to channels and report incoming messages" do
		condition = Async::Condition.new
		
		publisher = reactor.async do
			condition.wait
			Console.logger.debug("Publishing message...")
			client.publish 'news.breaking', 'AAA'
		end
		
		listener = reactor.async do
			Console.logger.debug("Subscribing...")
			client.subscribe 'news.breaking', 'news.weather', 'news.sport' do |context|
				Console.logger.debug("Waiting for message...")
				condition.signal
				
				type, name, message = context.listen
				
				Console.logger.debug("Got: #{type} #{name} #{message}")
				expect(type).to be == 'message'
				expect(name).to be == 'news.breaking'
				expect(message).to be == 'AAA'
			end
		end
		
		publisher.wait
		listener.wait
		
		# At this point, we should check if the client is still working. i.e. we don't leak the state of the subscriptions:
		
		expect(client.info).to be_a(Hash)
		
		client.close
	end
	
	it "can add subscriptions" do
		subscription = client.subscribe('news.breaking')
		
		listener = reactor.async do
			type, name, message = subscription.listen
			expect(message).to be == 'Sunny'
		end
		
		subscription.subscribe(['news.weather'])
		client.publish('news.weather', 'Sunny')
		
		listener.wait
	ensure
		subscription.close
	end
end
