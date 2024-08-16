# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'io/endpoint'
require 'io/endpoint/host_endpoint'
require 'io/endpoint/ssl_endpoint'

require_relative 'protocol/resp2'
require_relative 'protocol/authenticated'
require_relative 'protocol/selected'

module Async
	module Redis
		def self.local_endpoint(**options)
			Endpoint.local(**options)
		end
		
		# Represents a way to connect to a remote Redis server.
		class Endpoint < ::IO::Endpoint::Generic
			LOCALHOST = URI.parse("redis://localhost").freeze
			
			def self.local(**options)
				self.new(LOCALHOST, **options)
			end
			
			def self.remote(host, port = 6379, **options)
				self.new(URI.parse("redis://#{host}:#{port}"), **options)
			end
			
			SCHEMES = {
				'redis' => URI::Generic,
				'rediss' => URI::Generic,
			}
			
			def self.parse(string, endpoint = nil, **options)
				url = URI.parse(string).normalize
				
				return self.new(url, endpoint, **options)
			end
			
			# Construct an endpoint with a specified scheme, hostname, optional path, and options.
			#
			# @parameter scheme [String] The scheme to use, e.g. "redis" or "rediss".
			# @parameter hostname [String] The hostname to connect to (or bind to).
			# @parameter *options [Hash] Additional options, passed to {#initialize}.
			def self.for(scheme, hostname, credentials: nil, port: nil, database: nil, **options)
				uri_klass = SCHEMES.fetch(scheme.downcase) do
					raise ArgumentError, "Unsupported scheme: #{scheme.inspect}"
				end
				
				if database
					path = "/#{database}"
				end
				
				self.new(
					uri_klass.new(scheme, credentials&.join(":"), hostname, port, nil, path, nil, nil, nil).normalize,
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
			# @parameter scheme [String] The scheme to use, e.g. "redis" or "rediss".
			# @parameter hostname [String] The hostname to connect to (or bind to), overrides the URL hostname (used for SNI).
			# @parameter port [Integer] The port to bind to, overrides the URL port.
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
			
			def to_url
				url = @url.dup
				
				unless default_port?
					url.port = self.port
				end
				
				return url
			end
			
			def to_s
				"\#<#{self.class} #{self.to_url} #{@options}>"
			end
			
			def inspect
				"\#<#{self.class} #{self.to_url} #{@options.inspect}>"
			end
			
			attr :url
			
			def address
				endpoint.address
			end
			
			def secure?
				['rediss'].include?(self.scheme)
			end
			
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
			
			def default_port
				6379
			end
			
			def default_port?
				port == default_port
			end
			
			def port
				@options[:port] || @url.port || default_port
			end
			
			# The hostname is the server we are connecting to:
			def hostname
				@options[:hostname] || @url.hostname
			end
			
			def scheme
				@options[:scheme] || @url.scheme
			end
			
			def database
				@options[:database] || extract_database(@url.path)
			end
			
			private def extract_database(path)
				if path =~ /\/(\d+)$/
					return $1.to_i
				end
			end
			
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
			
			def ssl_context
				@options[:ssl_context] || OpenSSL::SSL::SSLContext.new.tap do |context|
					context.set_params(
						verify_mode: self.ssl_verify_mode
					)
				end
			end
			
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
			
			def endpoint
				@endpoint ||= build_endpoint
			end
			
			def endpoint=(endpoint)
				@endpoint = build_endpoint(endpoint)
			end
			
			def bind(*arguments, &block)
				endpoint.bind(*arguments, &block)
			end
			
			def connect(&block)
				endpoint.connect(&block)
			end
			
			def each
				return to_enum unless block_given?
				
				self.tcp_endpoint.each do |endpoint|
					yield self.class.new(@url, endpoint, **@options)
				end
			end
			
			def key
				[@url, @options]
			end
			
			def eql? other
				self.key.eql? other.key
			end
			
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
