# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "async/variable"
require "async/redis/cluster_client"
require "sus/fixtures/async"
require "securerandom"

describe Async::Redis::Context::Subscribe do
	include Sus::Fixtures::Async::ReactorContext
	
	with "in cluster environment" do
		let(:node_a) {"redis://redis-a:6379"}
		let(:node_b) {"redis://redis-b:6379"}
		let(:node_c) {"redis://redis-c:6379"}
		
		let(:endpoints) {[
			Async::Redis::Endpoint.parse(node_a),
			Async::Redis::Endpoint.parse(node_b),
			Async::Redis::Endpoint.parse(node_c)
		]}
		
		let(:cluster) {Async::Redis::ClusterClient.new(endpoints)}
		
		with "sharded subscriptions" do
			let(:shard_channel) {"cluster-shard:test:#{SecureRandom.uuid}"}
			let(:shard_message) {"cluster sharded message"}
			
			it "can subscribe to sharded channels and receive messages" do
				received_message = nil
				ready = Async::Variable.new
				
				# Set up the subscriber using cluster client's ssubscribe method
				subscriber_task = Async do
					cluster.ssubscribe(shard_channel) do |context|
						ready.resolve
						
						type, name, message = context.listen
						
						expect(type).to be == "smessage"
						expect(name).to be == shard_channel
						received_message = message
					end
				end
				
				# Set up the publisher
				publisher_task = Async do
					ready.wait
					
					slot = cluster.slot_for(shard_channel)
					publisher_client = cluster.client_for(slot)
					publisher_client.call("SPUBLISH", shard_channel, shard_message)
				end
				
				publisher_task.wait
				subscriber_task.wait
				
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
				channel_slots = channels.map {|channel| [channel, cluster.slot_for(channel)]}
				unique_slots = channel_slots.map(&:last).uniq
				
				# We should have channels distributed across different slots
				expect(unique_slots.size).to be > 1
				
				received_messages = []
				ready = Async::Variable.new
				subscriber_count = 0
				target_count = channels.size
				
				# Set up subscribers for each channel
				subscriber_tasks = channels.map do |channel|
					Async do
						slot = cluster.slot_for(channel)
						client = cluster.client_for(slot)
						
						client.ssubscribe(channel) do |context|
							subscriber_count += 1
							ready.resolve if subscriber_count == target_count
							
							type, name, message = context.listen
							received_messages << {channel: name, message: message, slot: slot}
						end
					end
				end
				
				# Set up publisher
				publisher_task = Async do
					ready.wait # Wait for all subscribers
					
					channels.each_with_index do |channel, index|
						slot = cluster.slot_for(channel)
						client = cluster.client_for(slot)
						
						client.call("SPUBLISH", channel, "message-#{index}")
					end
				end
				
				publisher_task.wait
				subscriber_tasks.each(&:wait)
				
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
					shard_client.call("SPUBLISH", shard_channel, "sharded message")
				end
				
				publisher_task.wait
				regular_task.wait
				shard_task.wait
				
				# Should have received both messages
				expect(received_messages.size).to be == 2
				
				# Verify message types
				message_types = received_messages.map {|msg| msg[:type]}
				expect(message_types).to be(:include?, "message")  # Regular pub/sub
				expect(message_types).to be(:include?, "smessage") # Sharded pub/sub
			end
			
			it "handles sharded subscription on same connection as regular subscription" do
				# Test that the unified Subscribe context works in cluster environment
				channel = "unified:test:#{SecureRandom.uuid}"
				shard_channel = "shard:unified:#{SecureRandom.uuid}"
				
				# Check if both channels hash to the same slot
				channel_slot = cluster.slot_for(channel)
				shard_slot = cluster.slot_for(shard_channel)
				
				# For this test to work, both channels must be on the same node
				# If they're not, we need to use the same hash tag to force them to the same slot
				if channel_slot != shard_slot
					# Use hash tags to force both channels to the same slot
					base_key = "{unified:#{SecureRandom.uuid}}"
					channel = "#{base_key}:regular"
					shard_channel = "#{base_key}:shard"
					
					# Verify they now hash to the same slot
					channel_slot = cluster.slot_for(channel)
					shard_slot = cluster.slot_for(shard_channel)
					expect(channel_slot).to be == shard_slot
				end
				
				client = cluster.client_for(channel_slot)
				
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
					
					# Both messages must be published from the same node (same slot)
					publisher_client = cluster.client_for(channel_slot)
					
					# Publish regular message
					publisher_client.publish(channel, "unified regular")
					
					# Publish sharded message
					publisher_client.call("SPUBLISH", shard_channel, "unified sharded")
				end
				
				publisher_task.wait
				subscriber_task.wait
				
				# Should receive both message types on same context
				expect(received_messages.size).to be == 2
				
				message_types = received_messages.map(&:first)
				expect(message_types).to be(:include?, "message")  # Regular
				expect(message_types).to be(:include?, "smessage") # Sharded
			end
		end
	end
end
