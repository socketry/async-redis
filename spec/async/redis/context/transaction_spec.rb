# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../client_context'

RSpec.describe Async::Redis::Context::Transaction, timeout: 5 do
	include_context Async::Redis::Client
	
	describe '#execute' do
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
		
		context 'with invalid command' do
			let(:key) {root[:thing]}
			
			it "results in error" do
				client.transaction do |context|
					context.multi
					context.set key, value
					context.lpop key
					
					expect do
						context.execute
					end.to raise_error(::Protocol::Redis::ServerError, /WRONGTYPE Operation against a key holding the wrong kind of value/)
				end
				
				# Even thought lpop failed, set was still applied:
				expect(client.get(key)).to be == value
			end
		end
	end
	
	describe '#discard' do
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
	
	describe '#watch' do
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
