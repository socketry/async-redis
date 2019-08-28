# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

RSpec.describe Async::Redis::Client, timeout: 5 do
	include_context Async::RSpec::Reactor

	let(:endpoint) {Async::IO::Endpoint.tcp('localhost', 5555)}

	it "should raise EOFError on unexpected disconnect" do
		server_task = reactor.async do
			endpoint.accept do |connection|
				stream = Async::IO::Stream.new(connection)
				stream.read(8)
				stream.close
			end
		end

		client = Async::Redis::Client.new(endpoint)
		
		expect do
			client.call("GET", "test")
		end.to raise_error(EOFError)
		
		client.close
		server_task.stop
	end
end
