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

require_relative 'protocol/resp'
require_relative 'pool'
require_relative 'context/multi'
require_relative 'context/subscribe'

require 'async/io'

module Async
	module Redis
		def self.local_endpoint
			Async::IO::Endpoint.tcp('localhost', 6379)
		end
		
		class Client
			def initialize(endpoint = Redis.local_endpoint, protocol = Protocol::RESP, **options)
				@endpoint = endpoint
				@protocol = protocol
				
				@pool = connect(**options)
			end
			
			attr :endpoint
			attr :protocol
			
			def self.open(*args, &block)
				client = self.new(*args)
				
				return client unless block_given?
				
				begin
					yield client
				ensure
					client.close
				end
			end
			
			def close
				@pool.close
			end
			
			def publish(channel, message)
				call('PUBLISH', channel, message)
			end
			
			def subscribe(*channels, &block)
				return unless block_given?
				
				response = nil
				
				@pool.acquire do |connection|
					response = Context::Subscribe.enter(connection, *channels) do |subscribe_context|
						yield subscribe_context
					end
				end
				
				return response
			end
			
			def multi(&block)
				return unless block_given?
				
				response = nil
				
				@pool.acquire do |connection|
					response = Context::Multi.enter(connection) do |multi_context|
						yield multi_context
					end
				end
				
				return response
			end
			
			def call(*arguments)
				@pool.acquire do |connection|
					connection.write_request(arguments)
					return connection.read_response
				end
			end
			
			protected
			
			def connect(connection_limit: nil)
				Pool.new(connection_limit) do
					peer = @endpoint.connect
						
					peer.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
					
					stream = IO::Stream.new(peer)
					
					@protocol.client(stream)
				end
			end
		end
	end
end
