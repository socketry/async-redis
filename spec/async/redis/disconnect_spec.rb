require 'async/redis/client'

RSpec.describe Async::Redis::Client, timeout: 5 do
	include_context Async::RSpec::Reactor

	let(:endpoint) { Async::IO::Endpoint.tcp('localhost', 5555) }

	it "should raise EOFError on unexpected disconnect" do
		server_task = reactor.async do
			endpoint.accept do |connection|
				stream = Async::IO::Stream.new(connection)
				stream.read(8)
				stream.close
			end
		end

		reactor.async do
			client = Async::Redis::Client.new(endpoint)
			expect { client.call("GET", "test") }.to raise_error(EOFError)
			client.close
			server_task.stop
		end

	end
end
