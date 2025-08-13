# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2019, by Mikael Henriksson.
# Copyright, 2019, by David Ortiz.
# Copyright, 2020, by Salim Semaoune.

require_relative "context/pipeline"
require_relative "context/transaction"
require_relative "context/subscribe"
require_relative "endpoint"

require "io/endpoint/host_endpoint"
require "async/pool/controller"
require "protocol/redis/methods"

require "io/stream"

module Async
	module Redis
		# Legacy.
		ServerError = ::Protocol::Redis::ServerError
		
		# A Redis client that provides connection pooling and context management.
		class Client
			include ::Protocol::Redis::Methods
			
			# Methods module providing Redis-specific functionality.
			module Methods
				# Subscribe to one or more channels for pub/sub messaging.
				# @parameter channels [Array(String)] The channels to subscribe to.
				# @yields {|context| ...} If a block is given, it will be executed within the subscription context.
				# 	@parameter context [Context::Subscribe] The subscription context.
				# @returns [Object] The result of the block if block given.
				# @returns [Context::Subscribe] The subscription context if no block given.
				def subscribe(*channels)
					context = Context::Subscribe.new(@pool, channels)
					
					return context unless block_given?
					
					begin
						yield context
					ensure
						context.close
					end
				end
				
				# Subscribe to one or more channel patterns for pub/sub messaging.
				# @parameter patterns [Array(String)] The channel patterns to subscribe to.
				# @yields {|context| ...} If a block is given, it will be executed within the subscription context.
				# 	@parameter context [Context::Subscribe] The subscription context.
				# @returns [Object] The result of the block if block given.
				# @returns [Context::Subscribe] The subscription context if no block given.
				def psubscribe(*patterns)
					context = Context::Subscribe.new(@pool, [])
					context.psubscribe(patterns)
					
					return context unless block_given?
					
					begin
						yield context
					ensure
						context.close
					end
				end
				
				# Subscribe to one or more sharded channels for pub/sub messaging (Redis 7.0+).
				# @parameter channels [Array(String)] The sharded channels to subscribe to.
				# @yields {|context| ...} If a block is given, it will be executed within the subscription context.
				# 	@parameter context [Context::Subscribe] The subscription context.
				# @returns [Object] The result of the block if block given.
				# @returns [Context::Subscribe] The subscription context if no block given.
				def ssubscribe(*channels)
					context = Context::Subscribe.new(@pool, [])
					context.ssubscribe(channels)
					
					return context unless block_given?
					
					begin
						yield context
					ensure
						context.close
					end
				end
				
				# Execute commands within a Redis transaction.
				# @yields {|context| ...} If a block is given, it will be executed within the transaction context.
				# 	@parameter context [Context::Transaction] The transaction context.
				# @returns [Object] The result of the block if block given.
				# @returns [Context::Transaction] Else if no block is given, returns the transaction context.
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
				
				# Execute commands in a pipeline for improved performance.
				# @yields {|context| ...} If a block is given, it will be executed within the pipeline context.
				# 	@parameter context [Context::Pipeline] The pipeline context.
				# @returns [Object] The result of the block if block given.
				# @returns [Context::Pipeline] The pipeline context if no block given.
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
				
				# Execute a Redis command directly.
				# @parameter arguments [Array] The command and its arguments.
				# @returns [Object] The response from the Redis server.
				def call(*arguments)
					@pool.acquire do |connection|
						connection.write_request(arguments)
						
						connection.flush
						
						return connection.read_response
					end
				end
				
				# Close the client and all its connections.
				def close
					@pool.close
				end
			end
			
			include Methods
			
			# Create a new Redis client.
			# @parameter endpoint [Endpoint] The Redis endpoint to connect to.
			# @parameter protocol [Protocol] The protocol to use for communication.
			# @parameter options [Hash] Additional options for the connection pool.
			def initialize(endpoint = Endpoint.local, protocol: endpoint.protocol, **options)
				@endpoint = endpoint
				@protocol = protocol
				
				@pool = make_pool(**options)
			end
			
			# @attribute [Endpoint] The Redis endpoint.
			attr :endpoint
			
			# @attribute [Protocol] The communication protocol.
			attr :protocol
			
			# Open a Redis client and optionally yield it in an async task.
			# @yields {|client, task| ...} If a block is given, yield the client in an async task.
			# 	@parameter client [Client] The Redis client instance.
			# 	@parameter task [Async::Task] The async task.
			# @returns [Client] The client if no block provided.
			# @returns [Object] The result of the block if block given.
			def self.open(*arguments, **options, &block)
				client = self.new(*arguments, **options)
				
				return client unless block_given?
				
				Async do |task|
					begin
						yield client, task
					ensure
						client.close
					end
				end.wait
			end
			
			protected
			
			def assign_default_tags(tags)
				tags[:endpoint] = @endpoint.to_s
				tags[:protocol] = @protocol.to_s
			end
			
			def make_pool(**options)
				self.assign_default_tags(options[:tags] ||= {})
				
				Async::Pool::Controller.wrap(**options) do
					peer = @endpoint.connect
					
					# We will manage flushing ourselves:
					peer.sync = true
					
					stream = ::IO::Stream(peer)
					
					@protocol.client(stream)
				end
			end
		end
	end
end
