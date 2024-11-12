# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require "client_context"

describe Async::Redis::Context::Transaction do
	include_context ClientContext
	
	describe "#execute" do
		let(:value) {"3"}
		
		it "can atomically execute commands" do
			response = nil
			
			client.transaction do |context|
				context.multi
				
				(0..5).each do |id|
					response = context.sync.set root[id], value
					expect(response).to be == "QUEUED"
				end
				
				response = context.execute
			end
			
			# all 5 SET + 1 EXEC commands should return OK
			expect(response).to be == ["OK"] * 6
			
			(0..5).each do |id|
				expect(client.call("GET", root[id])).to be == value
			end
		end
		
		it "can atomically increment integers" do
			client.transaction do |context|
				context.multi
				context.incr root[:foo]
				context.incr root[:bar]
				
				expect(context.execute).to be == [1, 1]
			end
		end
		
		with "an invalid command" do
			let(:key) {root[:thing]}
			
			it "results in error" do
				client.transaction do |context|
					context.multi
					context.set key, value
					context.lpop key
					
					expect do
						context.execute
					end.to raise_exception(::Protocol::Redis::ServerError, message: be =~ /WRONGTYPE Operation against a key holding the wrong kind of value/)
				end
				
				# Even thought lpop failed, set was still applied:
				expect(client.get(key)).to be == value
			end
		end
	end
	
	describe "#discard" do
		it "ignores increment" do
			client.transaction do |context|
				context.set root["foo"], "1"
				
				context.multi
				context.incr root["foo"]
				context.discard
				
				expect(context.sync.get(root["foo"])).to be == "1"
			end
		end
	end
	
	describe "#watch" do
		it "can atomically increment" do
			foo_key = root[:foo]
			
			client.transaction do |context|
				context.watch foo_key
				foo = context.sync.get(foo_key) || 0
				
				foo = foo + 1
				
				context.multi
				context.set foo_key, foo
				context.execute
			end
			
			expect(client.get(foo_key)).to be == "1"
		end
	end
end
