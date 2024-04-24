# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021, by Troex Nevelin.
# Copyright, 2023, by Samuel Williams.

require_relative '../../lib/async/redis'

# Friendly client wrapper that supports SSL, AUTH and db SELECT
class AsyncRedisClientWrapper
	class << self
		# @param url [String] Redis URL connection string
		# @param ssl_params [Hash] passed to OpenSSL::SSL::SSLContext
		# @param options [Hash] passed to Async::Redis::Client.new
		# @return [Async::Redis::Client]
		def call(url = 'redis://localhost:6379', ssl_params: nil, **options)
			uri = URI(url)

			endpoint = prepare_endpoint(uri, ssl_params)

			credentials = []
			credentials.push(uri.user) if uri.user && !uri.user.empty?
			credentials.push(uri.password) if uri.password && !uri.password.empty?

			db = uri.path[1..-1].to_i if uri.path

			protocol = AsyncRedisProtocolWrapper.new(db: db, credentials: credentials)

			Async::Redis::Client.new(endpoint, protocol: protocol, **options)
		end
		alias :connect :call

		# @param uri [URI]
		# @param ssl_params [Hash]
		# @return [::IO::Endpoint::Generic]
		def prepare_endpoint(uri, ssl_params = nil)
			tcp_endpoint = ::IO::Endpoint.tcp(uri.hostname, uri.port)
			case uri.scheme
			when 'redis'
				tcp_endpoint
			when 'rediss'
				ssl_context = OpenSSL::SSL::SSLContext.new
				ssl_context.set_params(ssl_params) if ssl_params
				::IO::SSLEndpoint.new(tcp_endpoint, ssl_context: ssl_context)
			else
				raise ArgumentError
			end
		end
	end
end

class AsyncRedisProtocolWrapper
	def initialize(db: 0, credentials: [], protocol: Async::Redis::Protocol::RESP2)
		@db = db
		@credentials = credentials
		@protocol = protocol
	end

	def client(stream)
		client = @protocol.client(stream)

		if @credentials.any?
			client.write_request(["AUTH", *@credentials])
			client.read_response
		end

		if @db
			client.write_request(["SELECT", @db])
			client.read_response
		end

		return client
	end
end

# can pass "redis://:pass@localhost:port/2" will connect using requirepass `AUTH password` and select DB
# "rediss://user:pass@localhost:port/0" will use SSL to connect and use ACL `AUTH user pass` in Redis 6+
Async do
	url = ENV["REDIS_URL"] || "redis://localhost:6379/0"
	client = AsyncRedisClientWrapper.connect(url)
	pp client.info
end
