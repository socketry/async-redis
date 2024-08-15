# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by David Ortiz.
# Copyright, 2019-2023, by Samuel Williams.

require 'async/redis/client'
require 'async/redis/context/pipeline'
require 'sus/fixtures/async'

describe Async::Redis::Context::Pipeline do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	let(:pool) {client.instance_variable_get(:@pool)}
	let(:pipeline) {Async::Redis::Context::Pipeline.new(pool)}
	
	let(:pairs) do
		{pipeline_key_1: '123', pipeline_key_2: '456'}
	end
	
	with '#call' do
		it 'accumulates commands without running them' do
			pairs.each do |key, value|
				pipeline.call('SET', key, value)
			end
			
			pipeline.close
			
			pairs.each do |key, value|
				expect(client.get(key)).to be == value
			end
		ensure
			client.close
		end
	end
	
	with '#collect' do
		it 'accumulates commands and runs them' do
			pairs.each do |key, value|
				pipeline.call('SET', key, value)
			end
			
			pipeline.flush
			
			pairs.each do |key, value|
				pipeline.call('GET', key)
			end
			
			expect(pipeline.collect).to be == pairs.values
		ensure
			pipeline.close
		end
	end
end
