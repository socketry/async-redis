# frozen_string_literal: true

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

require 'async/redis/client'

RSpec.describe Async::Redis::Context::Subscribe, timeout: 5 do
	include_context Async::RSpec::Reactor
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	
	it "should subscribe to channels and report incoming messages" do
		condition = Async::Condition.new
		
		publisher = reactor.async do
			condition.wait
			Async.logger.debug("Publishing message...")
			client.publish 'news.breaking', 'AAA'
		end
		
		listener = reactor.async do
			Async.logger.debug("Subscribing...")
			client.subscribe 'news.breaking', 'news.weather', 'news.sport' do |context|
				Async.logger.debug("Waiting for message...")
				condition.signal
				
				type, name, message = context.listen
				
				Async.logger.debug("Got: #{type} #{name} #{message}")
				expect(type).to be == 'message'
				expect(name).to be == 'news.breaking'
				expect(message).to be == 'AAA'
			end
		end
		
		publisher.wait
		listener.wait
		
		client.close
	end
end
