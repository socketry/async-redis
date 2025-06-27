# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "async/redis/client"
require "async/redis/protocol/authenticated"
require "sus/fixtures/async"

describe Async::Redis::Endpoint do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	
	with "#credentials" do
		it "can parse a url with username and password" do
			endpoint = Async::Redis::Endpoint.parse("redis://testuser:testpassword@localhost")
			expect(endpoint.credentials).to be == ["testuser", "testpassword"]
		end
		
		it "can parse a url with a blank username and password" do
			endpoint = Async::Redis::Endpoint.parse("redis://:testpassword@localhost")
			expect(endpoint.credentials).to be == ["testpassword"]
		end
		
		it "can parse a url with a password only" do
			endpoint = Async::Redis::Endpoint.parse("redis://testpassword@localhost")
			expect(endpoint.credentials).to be == ["testpassword"]
		end
	end
	
	with "#protocol" do
		it "defaults to RESP2" do
			expect(endpoint.protocol).to be == Async::Redis::Protocol::RESP2
		end
		
		with "database selection" do
			let(:endpoint) {Async::Redis.local_endpoint(database: 1)}
			
			it "selects the database" do
				expect(endpoint.protocol).to be_a(Async::Redis::Protocol::Selected)
				expect(endpoint.protocol.index).to be == 1
			end
		end
		
		with "credentials" do
			let(:credentials) {["testuser", "testpassword"]}
			let(:endpoint) {Async::Redis.local_endpoint(credentials: credentials)}
			
			it "authenticates with credentials" do
				expect(endpoint.protocol).to be_a(Async::Redis::Protocol::Authenticated)
				expect(endpoint.protocol.credentials).to be == credentials
			end
		end
	end
	
	with ".remote" do
		it "handles IPv4 addresses correctly" do
			endpoint = Async::Redis::Endpoint.remote("127.0.0.1", 6380)
			expect(endpoint.url.to_s).to be == "redis://127.0.0.1:6380"
			expect(endpoint.url.host).to be == "127.0.0.1"
			expect(endpoint.url.hostname).to be == "127.0.0.1"
		end
		
		it "handles IPv6 addresses correctly" do
			endpoint = Async::Redis::Endpoint.remote("::1", 6380)
			expect(endpoint.url.to_s).to be == "redis://[::1]:6380"
			expect(endpoint.url.host).to be == "[::1]"
			expect(endpoint.url.hostname).to be == "::1"
		end
		
		it "handles expanded IPv6 addresses correctly" do
			ipv6 = "2600:1f28:372:c404:5c2d:ce68:3620:cc4b"
			endpoint = Async::Redis::Endpoint.remote(ipv6, 6380)
			expect(endpoint.url.to_s).to be == "redis://[#{ipv6}]:6380"
			expect(endpoint.url.host).to be == "[#{ipv6}]"
			expect(endpoint.url.hostname).to be == ipv6
		end
	end
	
	with ".for" do
		it "handles IPv4 addresses correctly" do
			endpoint = Async::Redis::Endpoint.for("redis", "127.0.0.1", port: 6380)
			expect(endpoint.url.to_s).to be == "redis://127.0.0.1:6380"
			expect(endpoint.url.host).to be == "127.0.0.1"
			expect(endpoint.url.hostname).to be == "127.0.0.1"
			expect(endpoint.port).to be == 6380
		end
		
		it "handles IPv6 addresses correctly" do
			endpoint = Async::Redis::Endpoint.for("redis", "::1", port: 6380)
			expect(endpoint.url.to_s).to be == "redis://[::1]:6380"
			expect(endpoint.url.host).to be == "[::1]"
			expect(endpoint.url.hostname).to be == "::1"
			expect(endpoint.port).to be == 6380
		end
		
		it "handles expanded IPv6 addresses correctly" do
			ipv6 = "2600:1f28:372:c404:5c2d:ce68:3620:cc4b"
			endpoint = Async::Redis::Endpoint.for("redis", ipv6, port: 6380)
			expect(endpoint.url.to_s).to be == "redis://[#{ipv6}]:6380"
			expect(endpoint.url.host).to be == "[#{ipv6}]"
			expect(endpoint.url.hostname).to be == ipv6
			expect(endpoint.port).to be == 6380
		end
		
		it "handles credentials correctly" do
			endpoint = Async::Redis::Endpoint.for("redis", "localhost", credentials: ["user", "pass"], port: 6380)
			expect(endpoint.url.to_s).to be == "redis://user:pass@localhost:6380"
			expect(endpoint.url.userinfo).to be == "user:pass"
			expect(endpoint.credentials).to be == ["user", "pass"]
		end
		
		it "handles database selection correctly" do
			endpoint = Async::Redis::Endpoint.for("redis", "localhost", database: 2)
			expect(endpoint.url.to_s).to be == "redis://localhost/2"
			expect(endpoint.url.path).to be == "/2"
			expect(endpoint.database).to be == 2
		end
		
		it "handles secure connections correctly" do
			endpoint = Async::Redis::Endpoint.for("rediss", "localhost")
			expect(endpoint.url.to_s).to be == "rediss://localhost"
			expect(endpoint).to be(:secure?)
		end
		
		it "handles all parameters together correctly" do
			ipv6 = "2600:1f28:372:c404:5c2d:ce68:3620:cc4b"
			endpoint = Async::Redis::Endpoint.for("rediss", ipv6, 
				credentials: ["user", "pass"], 
				port: 6380, 
				database: 3
			)
			expect(endpoint.url.to_s).to be == "rediss://user:pass@[#{ipv6}]:6380/3"
			expect(endpoint.url.scheme).to be == "rediss"
			expect(endpoint.url.host).to be == "[#{ipv6}]"
			expect(endpoint.url.hostname).to be == ipv6
			expect(endpoint.url.userinfo).to be == "user:pass"
			expect(endpoint.url.port).to be == 6380
			expect(endpoint.url.path).to be == "/3"
			expect(endpoint).to be(:secure?)
			expect(endpoint.credentials).to be == ["user", "pass"]
			expect(endpoint.database).to be == 3
		end
	end
end
