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

require 'async/io/endpoint'
require_relative 'protocol/resp'

module Async
	module Redis
		def self.local_endpoint
			Async::IO::Endpoint.tcp('localhost', 6379)
		end
		
		class Client
			def initialize(endpoint, protocol = Protocol::RESP, **options)
				@endpoint = endpoint
				@protocol = protocol
				
				@stream = nil
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
				@stream.close
			end
			
			def call(*arguments)
				connect
				
				protocol = @protocol.new(@stream)
				protocol.write_command(arguments)
				
				return protocol.read_object
			end
			
			protected
			
			def connect
				@stream ||= Async::IO::Stream.new(@endpoint.connect)
			end
		end
	end
end
