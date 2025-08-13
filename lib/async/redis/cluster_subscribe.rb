# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Async
	module Redis
		# Context for managing sharded subscriptions across multiple Redis cluster nodes.
		# This class handles the complexity of subscribing to channels that may be distributed
		# across different shards in a Redis cluster.
		class ClusterSubscribe
			# Initialize a new shard subscription context.
			# @parameter cluster_client [ClusterClient] The cluster client to use.
			def initialize(cluster_client)
				@cluster_client = cluster_client
				@subscriptions = {}
				@channels = []
			end
			
			# Close all shard subscriptions.
			def close
				@subscriptions.each_value(&:close)
				@subscriptions.clear
			end
			
			# Listen for the next message from any subscribed shard.
			# This uses a simple round-robin approach to check each shard.
			# @returns [Array] The next message response, or nil if all connections closed.
			def listen
				return nil if @subscriptions.empty?
				
				# Simple round-robin checking of subscriptions
				@subscriptions.each_value do |subscription|
					# Non-blocking check for messages
					begin
						if response = subscription.listen
							return response
						end
					rescue => error
						# Handle connection errors gracefully
						Console.warn(self, "Error reading from shard subscription: #{error}")
					end
				end
				
				# If no immediate messages, do a blocking wait on the first subscription
				if first_subscription = @subscriptions.values.first
					first_subscription.listen
				end
			end
			
			# Iterate over all messages from all subscribed shards.
			# @yields {|response| ...} Block called for each message.
			# 	@parameter response [Array] The message response.
			def each
				return to_enum unless block_given?
				
				while response = self.listen
					yield response
				end
			end
			
			# Subscribe to additional sharded channels.
			# @parameter channels [Array(String)] The channels to subscribe to.
			def subscribe(channels)
				slots = @cluster_client.slots_for(channels)
				
				slots.each do |slot, channels_for_slot|
					if subscription = @subscriptions[slot]
						# Add to existing subscription for this shard
						subscription.ssubscribe(channels_for_slot)
					else
						# Create new subscription for this shard
						client = @cluster_client.client_for(slot)
						@subscriptions[slot] = client.ssubscribe(*channels_for_slot)
					end
				end
				
				@channels.concat(channels)
			end
			
			# Unsubscribe from sharded channels.
			# @parameter channels [Array(String)] The channels to unsubscribe from.
			def unsubscribe(channels)
				slots = @cluster_client.slots_for(channels)
				
				slots.each do |slot, channels_for_slot|
					if subscription = @subscriptions[slot]
						subscription.sunsubscribe(channels_for_slot)
						
						# Remove channels from our tracking
						@channels -= channels_for_slot
						
						# Check if this shard still has channels
						remaining_channels_for_slot = @channels.select {|ch| @cluster_client.slot_for(ch) == slot}
						
						# If no channels left for this shard, close and remove it
						if remaining_channels_for_slot.empty?
							subscription.close
							@subscriptions.delete(slot)
						end
					end
				end
			end
			
			# Get the list of currently subscribed channels.
			# @returns [Array(String)] The list of subscribed channels.
			def channels
				@channels.dup
			end
			
			# Get the number of active shard subscriptions.
			# @returns [Integer] The number of shard connections.
			def shard_count
				@subscriptions.size
			end
		end
	end
end
