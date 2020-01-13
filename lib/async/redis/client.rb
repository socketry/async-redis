# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'context/pipeline'
require_relative 'context/transaction'
require_relative 'context/subscribe'
require_relative 'context/psubscribe'

require_relative 'protocol/resp2'

require 'async/io'
require 'async/io/stream'
require 'async/pool/controller'

require 'protocol/redis/methods'

module Async
	module Redis
		# Legacy.
		ServerError = ::Protocol::Redis::ServerError
		
		def self.local_endpoint
			Async::IO::Endpoint.tcp('localhost', 6379)
		end
		
		class Client
			include ::Protocol::Redis::Methods
			
			def initialize(endpoint = Redis.local_endpoint, protocol = Protocol::RESP2, **options)
				@endpoint = endpoint
				@protocol = protocol
				
				@pool = connect(**options)
			end
			
			attr :endpoint
			attr :protocol
			
			# @return [client] if no block provided.
			# @yield [client, task] yield the client in an async task.
			def self.open(*args, &block)
				client = self.new(*args)
				
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
			
			def publish(channel, message)
				call('PUBLISH', channel, message)
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
			
      def psubscribe(*channels)
				context = Context::Psubscribe.new(@pool, channels)

				return context unless block_given?

				begin
					yield context
				ensure
					context.close
				end
			end

			def multi(&block)
				context = Context::Multi.new(@pool)
				
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
					
					peer.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
					
					stream = IO::Stream.new(peer)
					
					@protocol.client(stream)
				end
			end
		end
	end
end
