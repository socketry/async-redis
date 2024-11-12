# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by David Ortiz.
# Copyright, 2023-2024, by Samuel Williams.

require_relative 'client'
require 'io/stream'

module Async
	module Redis
		class SentinelClient
			DEFAULT_MASTER_NAME = 'mymaster'
			
			include ::Protocol::Redis::Methods
			include Client::Methods
			
			# Create a new instance of the SentinelClient.
			#
			# @property endpoints [Array(Endpoint)] The list of sentinel endpoints.
			# @property master_name [String] The name of the master instance, defaults to 'mymaster'.
			# @property role [Symbol] The role of the instance that you want to connect to, either `:master` or `:slave`.
			# @property protocol [Protocol] The protocol to use when connecting to the actual Redis server, defaults to {Protocol::RESP2}.
			def initialize(endpoints, master_name: DEFAULT_MASTER_NAME, role: :master, protocol: Protocol::RESP2, **options)
				@endpoints = endpoints
				@master_name = master_name
				@role = role
				@protocol = protocol
				
				# A cache of sentinel connections.
				@sentinels = {}
				
				@pool = make_pool(**options)
			end
			
			# @attribute [String] The name of the master instance.
			attr :master_name
			
			# @attribute [Symbol] The role of the instance that you want to connect to.
			attr :role
			
			def resolve_address(role = @role)
				case role
				when :master
					resolve_master
				when :slave
					resolve_slave
				else
					raise ArgumentError, "Unknown instance role #{role}"
				end => address
				
				Console.debug(self, "Resolved #{@role} address: #{address}")
				
				address or raise RuntimeError, "Unable to fetch #{role} via Sentinel."
			end
			
			def close
				super
				
				@sentinels.each do |_, client|
					client.close
				end
			end
			
			def failover(name = @master_name)
				sentinels do |client|
					return client.call('SENTINEL', 'FAILOVER', name)
				end
			end
			
			def masters
				sentinels do |client|
					return client.call('SENTINEL', 'MASTERS').map{|fields| fields.each_slice(2).to_h}
				end
			end
			
			def master(name = @master_name)
				sentinels do |client|
					return client.call('SENTINEL', 'MASTER', name).each_slice(2).to_h
				end
			end
			
			def resolve_master
				sentinels do |client|
					begin
						address = client.call('SENTINEL', 'GET-MASTER-ADDR-BY-NAME', @master_name)
					rescue Errno::ECONNREFUSED
						next
					end
					
					return Endpoint.remote(address[0], address[1]) if address
				end
				
				return nil
			end
			
			def resolve_slave
				sentinels do |client|
					begin
						reply = client.call('SENTINEL', 'SLAVES', @master_name)
					rescue Errno::ECONNREFUSED
						next
					end
					
					slaves = available_slaves(reply)
					next if slaves.empty?
					
					slave = select_slave(slaves)
					return Endpoint.remote(slave['ip'], slave['port'])
				end
				
				return nil
			end
			
			protected
			
			def assign_default_tags(tags)
				tags[:protocol] = @protocol.to_s
			end
			
			# Override the parent method. The only difference is that this one needs to resolve the master/slave address.
			def make_pool(**options)
				self.assign_default_tags(options[:tags] ||= {})
				
				Async::Pool::Controller.wrap(**options) do
					endpoint = resolve_address
					peer = endpoint.connect
					stream = ::IO::Stream(peer)
					
					@protocol.client(stream)
				end
			end
			
			def sentinels
				@endpoints.map do |endpoint|
					@sentinels[endpoint] ||= Client.new(endpoint)
					
					yield @sentinels[endpoint]
				end
			end
			
			def available_slaves(reply)
				# The reply is an array with the format: [field1, value1, field2,
				# value2, etc.].
				# When a slave is marked as down by the sentinel, the "flags" field
				# (comma-separated array) contains the "s_down" value.
				slaves = reply.map{|fields| fields.each_slice(2).to_h}
				
				slaves.reject do |slave|
					slave['flags'].split(',').include?('s_down')
				end
			end
			
			def select_slave(available_slaves)
				available_slaves.sample
			end
		end
	end
end
