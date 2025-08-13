# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "async/redis/cluster_client"
require "sus/fixtures/async"
require "securerandom"

describe Async::Redis::ClusterClient do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:node_a) {"redis://redis-a:6379"}
	let(:node_b) {"redis://redis-b:6379"}
	let(:node_c) {"redis://redis-c:6379"}
	
	let(:endpoints) {[
		Async::Redis::Endpoint.parse(node_a),
		Async::Redis::Endpoint.parse(node_b),
		Async::Redis::Endpoint.parse(node_c)
	]}
	
	let(:cluster) {subject.new(endpoints)}
	
	with "sharded subscriptions" do
		let(:shard_channel) {"cluster-shard:test:#{SecureRandom.uuid}"}
		let(:shard_message) {"cluster sharded message"}
		
		it "can subscribe to sharded channels and receive messages" do
			received_message = nil
			condition = Async::Condition.new
			
			# Get a client for the sharded channel
			slot = cluster.slot_for(shard_channel)
			subscriber_client = cluster.client_for(slot)
			
			# Set up the subscriber
			subscriber_task = reactor.async do
				subscriber_client.ssubscribe(shard_channel) do |context|
					condition.signal # Signal that we're ready
					
					type, name, message = context.listen
					
					expect(type).to be == "smessage"
					expect(name).to be == shard_channel
					received_message = message
				end
			end
			
			# Set up the publisher
			publisher_task = reactor.async do
				condition.wait # Wait for subscriber to be ready
				
				# For sharded pub/sub, we need to use SPUBLISH
				# Get a client (can be any node) to publish the message
				publisher_client = cluster.client_for(slot)
				
				begin
					# Try to use SPUBLISH if available (Redis 7.0+)
					publisher_client.call("SPUBLISH", shard_channel, shard_message)
				rescue => error
					# If SPUBLISH is not available, skip this test
					Console.warn("SPUBLISH not available, skipping sharded pub/sub test: #{error}")
					subscriber_task.stop
					return
				end
			end
			
			publisher_task.wait
			subscriber_task.stop
			
			expect(received_message).to be == shard_message
		end
		
		it "distributes sharded messages across cluster nodes" do
			# This test verifies that sharded pub/sub properly distributes
			# messages across different cluster nodes based on channel hash
			
			channels = [
				"shard:node:a:#{SecureRandom.uuid}",
				"shard:node:b:#{SecureRandom.uuid}",
				"shard:node:c:#{SecureRandom.uuid}"
			]
			
			# Find channels that map to different slots/nodes
			channel_slots = channels.map {|ch| [ch, cluster.slot_for(ch)]}
			unique_slots = channel_slots.map(&:last).uniq
			
			# We should have channels distributed across different slots
			expect(unique_slots.size).to be > 1
			
			received_messages = []
			condition = Async::Condition.new
			subscriber_count = 0
			target_count = channels.size
			
			# Set up subscribers for each channel
			subscriber_tasks = channels.map do |channel|
				reactor.async do
					slot = cluster.slot_for(channel)
					client = cluster.client_for(slot)
					
					client.ssubscribe(channel) do |context|
						subscriber_count += 1
						condition.signal if subscriber_count == target_count
						
						type, name, message = context.listen
						received_messages << {channel: name, message: message, slot: slot}
					end
				end
			end
			
			# Set up publisher
			publisher_task = reactor.async do
				condition.wait # Wait for all subscribers
				
				channels.each_with_index do |channel, index|
					slot = cluster.slot_for(channel)
					client = cluster.client_for(slot)
					
					begin
						client.call("SPUBLISH", channel, "message-#{index}")
					rescue => error
						Console.warn("SPUBLISH failed for #{channel}: #{error}")
						# Clean up and skip if SPUBLISH not available
						subscriber_tasks.each(&:stop)
						return
					end
				end
			end
			
			publisher_task.wait
			sleep(0.1) # Allow time for message delivery
			subscriber_tasks.each(&:stop)
			
			# Verify we received messages for different channels
			expect(received_messages.size).to be == channels.size
			
			# Verify messages were distributed to different slots
			received_slots = received_messages.map {|msg| msg[:slot]}.uniq
			expect(received_slots.size).to be > 1
		end
		
		it "can mix sharded and regular subscriptions on different nodes" do
			regular_channel = "regular:#{SecureRandom.uuid}"
			shard_channel = "shard:#{SecureRandom.uuid}"
			
			regular_slot = cluster.slot_for(regular_channel)
			shard_slot = cluster.slot_for(shard_channel)
			
			received_messages = []
			condition = Async::Condition.new
			ready_count = 0
			
			# Regular subscription on one node
			regular_task = reactor.async do
				client = cluster.client_for(regular_slot)
				client.subscribe(regular_channel) do |context|
					ready_count += 1
					condition.signal if ready_count == 2
					
					type, name, message = context.listen
					received_messages << {type: type, channel: name, message: message}
				end
			end
			
			# Sharded subscription on another node (if different)
			shard_task = reactor.async do
				client = cluster.client_for(shard_slot)
				client.ssubscribe(shard_channel) do |context|
					ready_count += 1
					condition.signal if ready_count == 2
					
					type, name, message = context.listen
					received_messages << {type: type, channel: name, message: message}
				end
			end
			
			# Publisher
			publisher_task = reactor.async do
				condition.wait # Wait for both subscribers
				
				# Publish to regular channel
				regular_client = cluster.client_for(regular_slot)
				regular_client.publish(regular_channel, "regular message")
				
				# Publish to sharded channel
				shard_client = cluster.client_for(shard_slot)
				begin
					shard_client.call("SPUBLISH", shard_channel, "sharded message")
				rescue => error
					Console.warn("SPUBLISH not available: #{error}")
					regular_task.stop
					shard_task.stop
					return
				end
			end
			
			publisher_task.wait
			sleep(0.1) # Allow time for message delivery
			regular_task.stop
			shard_task.stop
			
			# Should have received both messages
			expect(received_messages.size).to be == 2
			
			# Verify message types
			message_types = received_messages.map {|msg| msg[:type]}
			expect(message_types).to include("message")  # Regular pub/sub
			expect(message_types).to include("smessage") # Sharded pub/sub
		end
		
		it "handles sharded subscription on same connection as regular subscription" do
			# Test that the unified Subscribe context works in cluster environment
			channel = "unified:test:#{SecureRandom.uuid}"
			shard_channel = "shard:unified:#{SecureRandom.uuid}"
			
			slot = cluster.slot_for(channel)
			client = cluster.client_for(slot)
			
			received_messages = []
			condition = Async::Condition.new
			
			# Set up unified subscription
			subscriber_task = reactor.async do
				client.subscribe(channel) do |context|
					# Add sharded subscription to same context
					context.ssubscribe([shard_channel])
					
					condition.signal # Ready to receive
					
					# Listen for both message types
					2.times do
						response = context.listen
						received_messages << response
					end
				end
			end
			
			# Publisher
			publisher_task = reactor.async do
				condition.wait
				
				# Publish regular message
				client.publish(channel, "unified regular")
				
				# Publish sharded message
				begin
					client.call("SPUBLISH", shard_channel, "unified sharded")
				rescue => error
					Console.warn("SPUBLISH not available: #{error}")
					subscriber_task.stop
					return
				end
			end
			
			publisher_task.wait
			sleep(0.1) # Allow message delivery
			subscriber_task.stop
			
			# Should receive both message types on same context
			expect(received_messages.size).to be == 2
			
			message_types = received_messages.map(&:first)
			expect(message_types).to include("message")  # Regular
			expect(message_types).to include("smessage") # Sharded
		end
	end
end
