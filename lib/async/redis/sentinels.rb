# frozen_string_literal: true

module Async
	module Redis
		class SentinelsClient < Client
			def initialize(master_name, sentinels, role = :master, protocol = Protocol::RESP2, **options)
				@master_name = master_name
				@sentinel_endpoints = sentinels.map do |sentinel|
					Async::IO::Endpoint.tcp(sentinel[:host], sentinel[:port])
				end
				@role = role

				@protocol = protocol
				@pool = connect(**options)
			end

			private

			# Override the parent method. The only difference is that this one needs
			# to resolve the master/slave address.
			def connect(**options)
				Async::Pool::Controller.wrap(**options) do
					endpoint = resolve_address
					peer = endpoint.connect
					stream = IO::Stream.new(peer)

					@protocol.client(stream)
				end
			end

			def resolve_address
				address = case @role
									when :master then resolve_master
									when :slave then resolve_slave
									else raise ArgumentError, "Unknown instance role #{@role}"
									end

				address or raise RuntimeError, "Unable to fetch #{@role} via Sentinel."
			end

			def resolve_master
				@sentinel_endpoints.each do |sentinel_endpoint|
					client = Client.new(sentinel_endpoint)

					begin
						address = client.call('sentinel', 'get-master-addr-by-name', @master_name)
					rescue Errno::ECONNREFUSED
						next
					end

					return Async::IO::Endpoint.tcp(address[0], address[1]) if address
				end

				nil
			end

			def resolve_slave
				@sentinel_endpoints.each do |sentinel_endpoint|
					client = Client.new(sentinel_endpoint)

					begin
						reply = client.call('sentinel', 'slaves', @master_name)
					rescue Errno::ECONNREFUSED
						next
					end

					if slave = select_slave(reply)
						return Async::IO::Endpoint.tcp(slave['ip'], slave['port'])
					end
				end

				nil
			end

			def select_slave(slaves_cmd_reply)
				return nil unless slaves_cmd_reply

				# The reply is an array with the format: [field1, value1, field2,
				# value2, etc.].
				# When a slave is marked as down by the sentinel, the "flags" field
				# (comma-separated array) contains the "s_down" value.
				slaves_cmd_reply.map { |s| s.each_slice(2).to_h }
						.reject { |s| s.fetch('flags').split(',').include?('s_down') }
						.sample
			end
		end
	end
end
