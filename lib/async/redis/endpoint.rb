# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require "io/endpoint"
require "io/endpoint/host_endpoint"
require "io/endpoint/ssl_endpoint"
require "io/endpoint/unix_endpoint"

require_relative "protocol/resp2"
require_relative "protocol/authenticated"
require_relative "protocol/selected"

module Async
	module Redis
		# Create a local Redis endpoint.
		# @parameter options [Hash] Options for the endpoint.
		# @returns [Endpoint] A local Redis endpoint.
		def self.local_endpoint(**options)
			Endpoint.local(**options)
		end
		
		# Represents a way to connect to a remote Redis server.
		class Endpoint < ::IO::Endpoint::Generic
			LOCALHOST = URI::Generic.build(scheme: "redis", host: "localhost").freeze
			
			# Create a local Redis endpoint.
			# @parameter options [Hash] Additional options for the endpoint.
			# @returns [Endpoint] A local Redis endpoint.
			def self.local(**options)
				self.new(LOCALHOST, **options)
			end
			
			# Create a remote Redis endpoint.
			# @parameter host [String] The hostname to connect to.
			# @parameter port [Integer] The port to connect to.
			# @parameter options [Hash] Additional options for the endpoint.
			# @returns [Endpoint] A remote Redis endpoint.
			def self.remote(host, port = 6379, **options)
				# URI::Generic.build automatically handles IPv6 addresses correctly:
				self.new(URI::Generic.build(scheme: "redis", host: host, port: port), **options)
			end

			def self.unix(path, **options)
				unix_endpoint = ::IO::Endpoint.unix(path, Socket::PF_UNIX)
				self.new(URI::Generic.build(scheme: "unix", path:), unix_endpoint, **options)
			end
			
			SCHEMES = {
				"redis" => URI::Generic,
				"rediss" => URI::Generic,
			}
			
			# Parse a Redis URL string into an endpoint.
			# @parameter string [String] The URL string to parse.
			# @parameter endpoint [Endpoint] Optional underlying endpoint.
			# @parameter options [Hash] Additional options for the endpoint.
			# @returns [Endpoint] The parsed endpoint.
			def self.parse(string, endpoint = nil, **options)
				url = URI.parse(string)
				
				return self.new(url, endpoint, **options)
			end
			
			# Construct an endpoint with a specified scheme, hostname, optional path, and options.
			# If no scheme is provided, it will be auto-detected based on SSL context.
			#
			# @parameter scheme [String, nil] The scheme to use, e.g. "redis" or "rediss". If nil, will auto-detect.
			# @parameter hostname [String] The hostname to connect to (or bind to).
			# @parameter options [Hash] Additional options, passed to {#initialize}.
			def self.for(scheme, host, port: nil, database: nil, **options)
				# Auto-detect scheme if not provided:
				if default_scheme = options.delete(:scheme)
					scheme ||= default_scheme
				end
				
				scheme ||= options.key?(:ssl_context) ? "rediss" : "redis"
				
				uri_klass = SCHEMES.fetch(scheme.downcase) do
					raise ArgumentError, "Unsupported scheme: #{scheme.inspect}"
				end
				
				if database
					path = "/#{database}"
				end
				
				self.new(
					uri_klass.build(
						scheme: scheme,
						host: host,
						port: port,
						path: path,
					),
					**options
				)
			end
			
			# Coerce the given object into an endpoint.
			# @parameter url [String | Endpoint] The URL or endpoint to convert.
			def self.[](object)
				if object.is_a?(self)
					return object
				else
					self.parse(object.to_s)
				end
			end
			
			# Create a new endpoint.
			#
			# @parameter url [URI] The URL to connect to.
			# @parameter endpoint [Endpoint] The underlying endpoint to use.
			# @option scheme [String] The scheme to use, e.g. "redis" or "rediss".
			# @option hostname [String] The hostname to connect to (or bind to), overrides the URL hostname (used for SNI).
			# @option port [Integer] The port to bind to, overrides the URL port.
			# @option ssl_context [OpenSSL::SSL::SSLContext] The SSL context to use for secure connections.
			def initialize(url, endpoint = nil, **options)
				super(**options)
				
				raise ArgumentError, "URL must be absolute (include scheme, host): #{url}" unless url.absolute?
				
				@url = url
				
				if endpoint
					@endpoint = self.build_endpoint(endpoint)
				else
					@endpoint = nil
				end
			end
			
			# Convert the endpoint to a URL.
			# @returns [URI] The URL representation of the endpoint.
			def to_url
				url = @url.dup
				
				unless default_port?
					url.port = self.port
				end
				
				return url
			end
			
			# Convert the endpoint to a string representation.
			# @returns [String] A string representation of the endpoint.
			def to_s
				"\#<#{self.class} #{self.to_url} #{@options}>"
			end
			
			# Convert the endpoint to an inspectable string.
			# @returns [String] An inspectable string representation of the endpoint.
			def inspect
				"\#<#{self.class} #{self.to_url} #{@options.inspect}>"
			end
			
			attr :url
			
			# Get the address of the underlying endpoint.
			# @returns [String] The address of the endpoint.
			def address
				endpoint.address
			end
			
			# Check if the connection is secure (using TLS).
			# @returns [Boolean] True if the connection uses TLS.
			def secure?
				["rediss"].include?(self.scheme)
			end
			
			# Get the protocol for this endpoint.
			# @returns [Protocol] The protocol instance configured for this endpoint.
			def protocol
				protocol = @options.fetch(:protocol, Protocol::RESP2)
				
				if credentials = self.credentials
					protocol = Protocol::Authenticated.new(credentials, protocol)
				end
				
				if database = self.database
					protocol = Protocol::Selected.new(database, protocol)
				end
				
				return protocol
			end
			
			# Get the default port for Redis connections.
			# @returns [Integer] The default Redis port (6379).
			def default_port
				6379
			end
			
			# Check if the endpoint is using the default port.
			# @returns [Boolean] True if using the default port.
			def default_port?
				port == default_port
			end
			
			# Get the port for this endpoint.
			# @returns [Integer] The port number.
			def port
				@options[:port] || @url.port || default_port
			end
			
			# The hostname is the server we are connecting to:
			def hostname
				@options[:hostname] || @url.hostname
			end
			
			# Get the scheme for this endpoint.
			# @returns [String] The URL scheme (e.g., "redis" or "rediss").
			def scheme
				@options[:scheme] || @url.scheme
			end
			
			# Get the database number for this endpoint.
			# @returns [Integer | Nil] The database number or nil if not specified.
			def database
				@options[:database] || extract_database(@url.path)
			end
			
			private def extract_database(path)
				if path =~ /\/(\d+)$/
					return $1.to_i
				end
			end
			
			# Get the credentials for authentication.
			# @returns [Array(String) | Nil] The username and password credentials or nil if not specified.
			def credentials
				@options[:credentials] || extract_userinfo(@url.userinfo)
			end
			
			private def extract_userinfo(userinfo)
				if userinfo
					credentials = userinfo.split(":").reject(&:empty?)
					
					if credentials.any?
						return credentials
					end
				end
			end
			
			# Check if the endpoint is connecting to localhost.
			# @returns [Boolean] True if connecting to localhost.
			def localhost?
				@url.hostname =~ /^(.*?\.)?localhost\.?$/
			end
			
			# We don't try to validate peer certificates when talking to localhost because they would always be self-signed.
			def ssl_verify_mode
				if self.localhost?
					OpenSSL::SSL::VERIFY_NONE
				else
					OpenSSL::SSL::VERIFY_PEER
				end
			end
			
			# Get the SSL context for secure connections.
			# @returns [OpenSSL::SSL::SSLContext] The SSL context configured for this endpoint.
			def ssl_context
				@options[:ssl_context] || OpenSSL::SSL::SSLContext.new.tap do |context|
					context.set_params(
						verify_mode: self.ssl_verify_mode
					)
				end
			end
			
			# Build the underlying endpoint with optional SSL wrapping.
			# @parameter endpoint [IO::Endpoint] Optional base endpoint to wrap.
			# @returns [IO::Endpoint] The built endpoint, potentially wrapped with SSL.
			def build_endpoint(endpoint = nil)
				endpoint ||= tcp_endpoint
				
				if secure?
					# Wrap it in SSL:
					return ::IO::Endpoint::SSLEndpoint.new(endpoint,
						ssl_context: self.ssl_context,
						hostname: @url.hostname,
						timeout: self.timeout,
					)
				end
				
				return endpoint
			end
			
			# Get the underlying endpoint, building it if necessary.
			# @returns [IO::Endpoint] The underlying endpoint for connections.
			def endpoint
				@endpoint ||= build_endpoint
			end
			
			# Set the underlying endpoint.
			# @parameter endpoint [IO::Endpoint] The endpoint to wrap and use.
			def endpoint=(endpoint)
				@endpoint = build_endpoint(endpoint)
			end
			
			# Bind to the endpoint and yield the server socket.
			# @parameter arguments [Array] Arguments to pass to the underlying endpoint bind method.
			# @yields [IO] The bound server socket.
			def bind(*arguments, &block)
				endpoint.bind(*arguments, &block)
			end
			
			# Connect to the endpoint and yield the client socket.
			# @yields [IO] The connected client socket.
			def connect(&block)
				endpoint.connect(&block)
			end
			
			# Iterate over each possible endpoint variation.
			# @yields [Endpoint] Each endpoint variant.
			def each
				return to_enum unless block_given?
				
				self.tcp_endpoint.each do |endpoint|
					yield self.class.new(@url, endpoint, **@options)
				end
			end
			
			# Get the key for hashing and equality comparison.
			# @returns [Array] The key components for this endpoint.
			def key
				[@url, @options]
			end
			
			# Check if this endpoint is equal to another.
			# @parameter other [Endpoint] The other endpoint to compare with.
			# @returns [Boolean] True if the endpoints are equal.
			def eql? other
				self.key.eql? other.key
			end
			
			# Get the hash code for this endpoint.
			# @returns [Integer] The hash code based on the endpoint's key.
			def hash
				self.key.hash
			end
			
			protected
			
			def tcp_options
				options = @options.dup
				
				options.delete(:scheme)
				options.delete(:port)
				options.delete(:hostname)
				options.delete(:ssl_context)
				options.delete(:protocol)
				
				return options
			end
			
			def tcp_endpoint
				::IO::Endpoint.tcp(self.hostname, port, **tcp_options)
			end
		end
	end
end
