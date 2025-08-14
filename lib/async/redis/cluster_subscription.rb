# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "async/limited_queue"
require "async/barrier"

module Async
	module Redis
		# Context for managing sharded subscriptions across multiple Redis cluster nodes.
		# This class handles the complexity of subscribing to channels that may be distributed
		# across different shards in a Redis cluster.
		class ClusterSubscription
			# Represents a failure in the subscription process, e.g. network issues, shard failures.
			class SubscriptionError < StandardError
			end
			
			# Initialize a new shard subscription context.
			# @parameter cluster_client [ClusterClient] The cluster client to use.
			def initialize(cluster_client, queue: Async::LimitedQueue.new)
				@cluster_client = cluster_client
				@subscriptions = {}
				@channels = []
				
				@barrier = Async::Barrier.new
				@queue = queue
			end
			
			# Close all shard subscriptions.
			def close
				if barrier = @barrier
					@barrier = nil
					barrier.stop
				end
				
				@subscriptions.each_value(&:close)
				@subscriptions.clear
			end
			
			# Listen for the next message from any subscribed shard.
			# @returns [Array] The next message response.
			# @raises [SubscriptionError] If the subscription has failed for any reason.
			def listen
				@queue.pop
			rescue => error
				raise SubscriptionError, "Failed to read message!"
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
						subscription = @subscriptions[slot] = client.ssubscribe(*channels_for_slot)
						
						@barrier.async do
							# This is optimistic, in other words, subscription.listen will also fail on close.
							until subscription.closed?
								@queue << subscription.listen
							end
						ensure
							# If we are exiting here for any reason OTHER than the subscription was closed, we need to re-create the subscription state:
							unless subscription.closed?
								@queue.close
							end
						end
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
							@subscriptions.delete(slot)
							subscription.close
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
