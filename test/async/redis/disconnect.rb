# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by Jeremy Jung.
# Copyright, 2019, by David Ortiz.
# Copyright, 2019-2023, by Samuel Williams.

require 'async/redis/client'
require 'sus/fixtures/async'

describe Async::Redis::Client do
	include Sus::Fixtures::Async::ReactorContext

	let(:endpoint) {::IO::Endpoint.tcp('localhost', 5555)}

	it "should raise error on unexpected disconnect" do
		server_task = reactor.async do
			endpoint.accept do |connection|
				connection.read(8)
				connection.close
			end
		end

		client = Async::Redis::Client.new(endpoint)
		
		expect do
			client.call("GET", "test")
		end.to raise_exception(Errno::ECONNRESET)
		
		client.close
		server_task.stop
	end
end
