# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.
# Copyright, 2025, by Travis Bell.

require_relative "client"
require "io/stream"

module Async
	module Redis
		# A Redis cluster client that manages multiple Redis instances and handles cluster operations.
		class ClusterClient
			# Raised when cluster configuration cannot be reloaded.
			class ReloadError < StandardError
			end
			
			# Raised when no nodes are found for a specific slot.
			class SlotError < StandardError
			end
			
			Node = Struct.new(:id, :endpoint, :role, :health, :client)
			
			# A map that stores ranges and their associated values for efficient lookup.
			class RangeMap
				# Initialize a new RangeMap.
				def initialize
					@ranges = []
				end
				
				# Add a range-value pair to the map.
				# @parameter range [Range] The range to map.
				# @parameter value [Object] The value to associate with the range.
				# @returns [Object] The added value.
				def add(range, value)
					@ranges << [range, value]
					
					return value
				end
				
				# Find the value associated with a key within any range.
				# @parameter key [Object] The key to find.
				# @yields {...} Block called if no range contains the key.
				# @returns [Object] The value if found, result of block if given, or nil.
				def find(key)
					@ranges.each do |range, value|
						return value if range.include?(key)
					end
					
					if block_given?
						return yield
					end
					
					return nil
				end
				
				# Iterate over all values in the map.
				# @yields {|value| ...} Block called for each value.
				# 	@parameter value [Object] The value from the range-value pair.
				def each
					@ranges.each do |range, value|
						yield value
					end
				end
				
				# Get a random value from the map.
				# @returns [Object] A randomly selected value, or nil if map is empty.
				def sample
					return nil if @ranges.empty?
					
					range, value = @ranges.sample
					
					return value
				end
				
				# Clear all ranges from the map.
				def clear
					@ranges.clear
				end
			end
			
			# Create a new instance of the cluster client.
			#
			# @property endpoints [Array(Endpoint)] The list of cluster endpoints.
			def initialize(endpoints, **options)
				@endpoints = endpoints
				@options = options
				@shards = nil
			end
			
			# Execute a block with clients for the given keys, grouped by cluster slot.
			# @parameter keys [Array] The keys to find clients for.
			# @parameter role [Symbol] The role of nodes to use (:master or :slave).
			# @parameter attempts [Integer] Number of retry attempts for cluster errors.
			# @yields {|client, keys| ...} Block called for each client-keys pair.
			# 	@parameter client [Client] The Redis client for the slot.
			# 	@parameter keys [Array] The keys handled by this client.
			def clients_for(*keys, role: :master, attempts: 3)
				slots = slots_for(keys)
				
				slots.each do |slot, keys|
					yield client_for(slot, role), keys
				end
			rescue ServerError => error
				Console.warn(self, error)
				
				if error.message =~ /MOVED|ASK/
					reload_cluster!
					
					attempts -= 1
					
					retry if attempts > 0
					
					raise
				else
					raise
				end
			end
			
			# Get a client for a specific slot.
			# @parameter slot [Integer] The cluster slot number.
			# @parameter role [Symbol] The role of node to get (:master or :slave).
			# @returns [Client] The Redis client for the slot.
			def client_for(slot, role = :master)
				unless @shards
					reload_cluster!
				end
				
				if nodes = @shards.find(slot)
					nodes = nodes.select{|node| node.role == role}
				else
					raise SlotError, "No nodes found for slot #{slot}"
				end
				
				if node = nodes.sample
					return (node.client ||= Client.new(node.endpoint, **@options))
				end
			end
			
			# Get any available client from the cluster.
			# This is useful for operations that don't require slot-specific routing,
			# such as global pub/sub operations, INFO commands, or other cluster-wide operations.
			# @parameter role [Symbol] The role of node to get (:master or :slave).
			# @returns [Client] A Redis client for any available node.
			def any_client(role = :master)
				unless @shards
					reload_cluster!
				end
				
				# Sample a random shard to get better load distribution
				if nodes = @shards.sample
					nodes = nodes.select{|node| node.role == role}
					
					if node = nodes.sample
						return (node.client ||= Client.new(node.endpoint, **@options))
					end
				end
				
				# Fallback to slot 0 if sampling fails
				client_for(0, role)
			end
			
			# Execute a Redis command on any available cluster node.
			# This is useful for commands that don't require slot-specific routing.
			# @parameter command [String] The Redis command to execute.
			# @parameter arguments [Array] The command arguments.
			# @returns [Object] The result of the Redis command.
			def call(command, *arguments)
				any_client.call(command, *arguments)
			end
			
			protected
			
			def reload_cluster!(endpoints = @endpoints)
				@endpoints.each do |endpoint|
					client = Client.new(endpoint, **@options)
					
					shards = RangeMap.new
					endpoints = []
					
					client.call("CLUSTER", "SHARDS").each do |shard|
						shard = shard.each_slice(2).to_h
						
						slots = shard["slots"]
						range = Range.new(*slots)
						
						nodes = shard["nodes"].map do |node|
							node = node.each_slice(2).to_h
							endpoint = Endpoint.for(endpoint.scheme, node["endpoint"], port: node["port"])
							
							# Collect all endpoints:
							endpoints << endpoint
							
							Node.new(node["id"], endpoint, node["role"].to_sym, node["health"].to_sym)
						end
						
						shards.add(range, nodes)
					end
					
					@shards = shards
					# @endpoints = @endpoints | endpoints
					
					return true
				rescue Errno::ECONNREFUSED
					next
				end
				
				raise ReloadError, "Failed to reload cluster configuration."
			end
			
			XMODEM_CRC16_LOOKUP = [
				0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
				0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
				0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
				0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
				0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
				0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
				0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
				0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
				0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
				0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
				0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
				0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
				0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
				0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
				0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
				0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
				0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
				0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
				0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
				0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
				0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
				0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
				0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
				0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
				0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
				0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
				0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
				0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
				0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
				0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
				0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
				0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0
			].freeze
			
			# This is the CRC16 algorithm used by Redis Cluster to hash keys.
			# Copied from https://github.com/antirez/redis-rb-cluster/blob/master/crc16.rb
			def crc16(bytes)
				sum = 0
				
				bytes.each_byte do |byte|
					sum = ((sum << 8) & 0xffff) ^ XMODEM_CRC16_LOOKUP[((sum >> 8) ^ byte) & 0xff]
				end
				
				return sum
			end
			
			public
			
			HASH_SLOTS = 16_384
			
			# Return Redis::Client for a given key.
			# Modified from https://github.com/antirez/redis-rb-cluster/blob/master/cluster.rb#L104-L117
			def slot_for(key)
				key = key.to_s
				
				if s = key.index("{")
					if e = key.index("}", s + 1) and e != s + 1
						key = key[s + 1..e - 1]
					end
				end
				
				return crc16(key) % HASH_SLOTS
			end
			
			# Calculate the hash slots for multiple keys.
			# @parameter keys [Array] The keys to calculate slots for.
			# @returns [Hash] A hash mapping slot numbers to arrays of keys.
			def slots_for(keys)
				slots = Hash.new{|hash, key| hash[key] = []}
				
				keys.each do |key|
					slots[slot_for(key)] << key
				end
				
				return slots
			end
			
			# Subscribe to one or more channels for pub/sub messaging in cluster environment.
			# 
			# NOTE: Regular pub/sub in Redis Cluster is GLOBAL - messages propagate to all nodes.
			# This method is a convenience that subscribes via an arbitrary cluster node.
			# The choice of node does not affect which messages you receive, since regular
			# pub/sub messages are broadcast to all nodes in the cluster.
			# 
			# For slot-aware pub/sub, use ssubscribe() instead (Redis 7.0+).
			# 
			# @parameter channels [Array(String)] The channels to subscribe to.
			# @yields {|context| ...} If a block is given, it will be executed within the subscription context.
			# 	@parameter context [Context::Subscribe] The subscription context.
			# @returns [Object] The result of the block if block given.
			# @returns [Context::Subscribe] The subscription context if no block given.
			def subscribe(*channels)
				# For regular pub/sub, use any available node since messages are global
				client = any_client
				
				client.subscribe(*channels) do |context|
					if block_given?
						yield context
					else
						return context
					end
				end
			end
			
			# Subscribe to one or more channel patterns for pub/sub messaging in cluster environment.
			# 
			# NOTE: Pattern subscriptions in Redis Cluster are GLOBAL - they match channels
			# across all nodes. This method is a convenience that subscribes via an arbitrary
			# cluster node. Pattern matching works across the entire cluster regardless of
			# which node you subscribe from.
			# 
			# @parameter patterns [Array(String)] The channel patterns to subscribe to.
			# @yields {|context| ...} If a block is given, it will be executed within the subscription context.
			# 	@parameter context [Context::Subscribe] The subscription context.
			# @returns [Object] The result of the block if block given.
			# @returns [Context::Subscribe] The subscription context if no block given.
			def psubscribe(*patterns)
				# For pattern subscriptions, use any available node since patterns are global
				client = any_client
				
				client.psubscribe(*patterns) do |context|
					if block_given?
						yield context
					else
						return context
					end
				end
			end
			
			# Subscribe to one or more sharded channels for pub/sub messaging in cluster environment (Redis 7.0+).
			# The subscription will be created on the node responsible for the channel's hash slot.
			# @parameter channels [Array(String)] The sharded channels to subscribe to.
			# @yields {|context| ...} If a block is given, it will be executed within the subscription context.
			# 	@parameter context [Context::Subscribe] The subscription context.
			# @returns [Object] The result of the block if block given.
			# @returns [Context::Subscribe] The subscription context if no block given.
			def ssubscribe(*channels)
				# For sharded subscriptions, route to appropriate node based on channel hash
				slot = channels.any? ? slot_for(channels.first) : 0
				client = client_for(slot)
				
				client.ssubscribe(*channels) do |context|
					if block_given?
						yield context
					else
						return context
					end
				end
			end
		end
	end
end
