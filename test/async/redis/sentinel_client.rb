# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require "async/redis/sentinel_client"
require "sus/fixtures/async"
require "openssl"

describe Async::Redis::SentinelClient do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:sentinels) {[
		Async::Redis::Endpoint.parse("redis://localhost:26379")
	]}
	
	with "initialization" do
		it "can be created with basic parameters" do
			client = subject.new(sentinels)
			expect(client.master_name).to be == "mymaster"
			expect(client.role).to be == :master
		end
		
		it "accepts master_options parameter" do
			master_options = {database: 1, timeout: 5}
			client = subject.new(sentinels, master_options: master_options)
			
			# Test that the options are used by checking the instance variables
			expect(client.instance_variable_get(:@master_options)).to be == master_options
		end
		
		it "accepts slave_options parameter" do
			master_options = {database: 1}
			slave_options = {database: 2, timeout: 10}
			client = subject.new(sentinels, master_options: master_options, slave_options: slave_options)
			
			expect(client.instance_variable_get(:@slave_options)).to be == slave_options
		end
		
		it "uses master_options as fallback for slaves when slave_options not provided" do
			master_options = {database: 1, timeout: 5}
			client = subject.new(sentinels, master_options: master_options)
			
			expect(client.instance_variable_get(:@slave_options)).to be == master_options
		end
		
		it "handles empty options gracefully" do
			client = subject.new(sentinels)
			
			expect(client.instance_variable_get(:@master_options)).to be == {}
			expect(client.instance_variable_get(:@slave_options)).to be == {}
		end
	end
	
	with "scheme detection" do
		let(:client) { subject.new(sentinels) }
		
		it "detects redis scheme for options without ssl_context" do
			options = {database: 1, timeout: 5}
			expect(client.send(:scheme_for_options, options)).to be == "redis"
		end
		
		it "detects rediss scheme for options with ssl_context" do
			ssl_context = OpenSSL::SSL::SSLContext.new
			options = {ssl_context: ssl_context}
			expect(client.send(:scheme_for_options, options)).to be == "rediss"
		end
		
		it "detects redis scheme for empty options" do
			expect(client.send(:scheme_for_options, {})).to be == "redis"
		end
	end
	
	with "endpoint options by role" do
		let(:master_options) { {database: 1, timeout: 5} }
		let(:slave_options) { {database: 2, timeout: 10} }
		let(:client) { subject.new(sentinels, master_options: master_options, slave_options: slave_options) }
		
		it "stores master options correctly" do
			expect(client.instance_variable_get(:@master_options)).to be == master_options
		end
		
		it "stores slave options correctly" do
			expect(client.instance_variable_get(:@slave_options)).to be == slave_options
		end
	end
	
	with "role-specific scheme handling" do
		it "uses correct scheme for master with SSL" do
			ssl_context = OpenSSL::SSL::SSLContext.new
			master_options = {ssl_context: ssl_context}
			client = subject.new(sentinels, master_options: master_options)
			
			expect(client.send(:scheme_for_options, master_options)).to be == "rediss"
		end
		
		it "uses different schemes for master vs slave when options differ" do
			ssl_context = OpenSSL::SSL::SSLContext.new
			master_options = {ssl_context: ssl_context}  # SSL enabled
			slave_options = {database: 1}  # No SSL
			
			client = subject.new(sentinels, master_options: master_options, slave_options: slave_options)
			
			expect(client.send(:scheme_for_options, master_options)).to be == "rediss"
			expect(client.send(:scheme_for_options, slave_options)).to be == "redis"
		end
	end
end
