require 'async/redis/client'
require 'async/redis/context/pipeline'

RSpec.describe Async::Redis::Context::Pipeline, timeout: 5 do
	include_context Async::RSpec::Reactor
	
	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	let(:pool) {client.instance_variable_get(:@pool)}
	let(:pipeline) {Async::Redis::Context::Pipeline.new(pool)}
	
	let(:example_key_vals) do
		{pipeline_key_1: '123', pipeline_key_2: '456'}
	end
	
	describe '.call' do
		it 'accumulates commands without running them' do
			example_key_vals.each do |k, v|
				pipeline.call('SET', k, v)
			end
			
			pipeline.close
			
			example_key_vals.keys do |k|
				expect(client.get k).to be nil
			end
			
			client.close
		end
	end

	describe '.run' do
		it 'runs the accumulated commands' do
			example_key_vals.each do |k, v|
				pipeline.call('SET', k, v)
			end
			
			pipeline.close
			
			example_key_vals.keys do |k, v|
				expect(client.get k).to eq v
			end
			
			client.close
		end
	end
end
