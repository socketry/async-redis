# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by Jeremy Jung.
# Copyright, 2019, by David Ortiz.
# Copyright, 2019-2024, by Samuel Williams.

require "async/redis/client"
require "sus/fixtures/async"

describe Async::Redis::Client do
	include Sus::Fixtures::Async::ReactorContext
	
	# Intended to not be connected:
	let(:endpoint) {Async::Redis::Endpoint.local(port: 5555)}
	
	before do
		@server_endpoint = ::IO::Endpoint.tcp("localhost").bound
	end
	
	after do
		@server_endpoint&.close
	end
	
	it "should raise error on unexpected disconnect" do
		server_task = Async do
			@server_endpoint.accept do |connection|
				connection.read(8)
				connection.close
			end
		end
		
		client = Async::Redis::Client.new(
			@server_endpoint.local_address_endpoint,
			protocol: Async::Redis::Protocol::RESP2,
		)
		
		expect do
			client.call("GET", "test")
		end.to raise_exception(Errno::ECONNRESET)
		
		client.close
		server_task.stop
	end
end
