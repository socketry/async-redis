# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2019, by Mikael Henriksson.
# Copyright, 2019, by David Ortiz.
# Copyright, 2020, by Salim Semaoune.

require_relative 'context/pipeline'
require_relative 'context/transaction'
require_relative 'context/subscribe'

require_relative 'protocol/resp2'

require 'async/io'
require 'async/io/stream'
require 'async/pool/controller'

require 'protocol/redis/methods'

module Async
	module Redis
		# Legacy.
		ServerError = ::Protocol::Redis::ServerError
		
		def self.local_endpoint(port: 6379)
			Async::IO::Endpoint.tcp('localhost', port)
		end
		
		class Client
			include ::Protocol::Redis::Methods
			
			def initialize(endpoint = Redis.local_endpoint, protocol: Protocol::RESP2, **options)
				@endpoint = endpoint
				@protocol = protocol
				
				@pool = connect(**options)
			end
			
			attr :endpoint
			attr :protocol
			
			# @return [client] if no block provided.
			# @yield [client, task] yield the client in an async task.
			def self.open(*arguments, &block)
				client = self.new(*arguments)
				
				return client unless block_given?
				
				Async do |task|
					begin
						yield client, task
					ensure
						client.close
					end
				end.wait
			end
			
			def close
				@pool.close
			end
			
			def subscribe(*channels)
				context = Context::Subscribe.new(@pool, channels)
				
				return context unless block_given?
				
				begin
					yield context
				ensure
					context.close
				end
			end
			
			def transaction(&block)
				context = Context::Transaction.new(@pool)
				
				return context unless block_given?
				
				begin
					yield context
				ensure
					context.close
				end
			end
			
			alias multi transaction
			
			def pipeline(&block)
				context = Context::Pipeline.new(@pool)
				
				return context unless block_given?
				
				begin
					yield context
				ensure
					context.close
				end
			end
			
			# Deprecated.
			alias nested pipeline
			
			def call(*arguments)
				@pool.acquire do |connection|
					connection.write_request(arguments)
					
					connection.flush
					
					return connection.read_response
				end
			end
			
			protected
			
			def connect(**options)
				Async::Pool::Controller.wrap(**options) do
					peer = @endpoint.connect
					
					# We will manage flushing ourselves:
					peer.sync = true
					
					stream = IO::Stream.new(peer)
					
					@protocol.client(stream)
				end
			end
		end
	end
end
