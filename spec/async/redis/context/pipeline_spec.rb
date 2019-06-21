require 'async/redis/client'
require 'async/redis/context/pipeline'

RSpec.describe Async::Redis::Context::Pipeline, timeout: 5 do
	include_context Async::RSpec::Reactor

	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	let(:pool) {client.instance_variable_get(:@pool)}
	let(:pipeline) {Async::Redis::Context::Pipeline.new(pool)}

	let(:small_key_count) { 50 }
	let(:large_key_count) { 1500 }
	let(:key_prefix) { 'pipeline_key_' }
	let(:keys) { large_key_count.times.map { |i| "#{key_prefix}#{i}" } }

	it 'accumulates commands without running them prematurely' do
		small_key_count.times do |i|
			pipeline.set(keys[i], i)
			expect(client.keys("#{key_prefix}*").length).to eq 0
		end

		pipeline.run
		expect(client.keys("#{key_prefix}*").length).to eq small_key_count

		pipeline.close
		client.close
	end

	it 'can read back the responses to each request' do
		small_key_count.times do |i|
			pipeline.set(keys[i], i)
		end

		pipeline.close

		client.close
	end

	it 'does not send any commands more than once' do
		small_key_count.times do |i|
			pipeline.set("#{key_prefix}#{i}", i)
		end

		pipeline.run
		
		# increment each key once
		small_key_count.times do |i|
			pipeline.incr(keys[i])
		end

		pipeline.close

		small_key_count.times do |i|
			expect(client.get(keys[i]).to_i).to eq i+1
		end

		client.close
	end

	it 'behaves well even when the buffer gets full' do
		large_key_count.times do |i|
			pipeline.set(keys[i], i)
		end

		pipeline.close

		client.close
	end
end
