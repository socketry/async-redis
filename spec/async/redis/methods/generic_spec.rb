# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# Copyright, 2018, by Huba Nagy.
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

RSpec.describe Protocol::Redis::Methods::Generic, timeout: 5 do
	include_context Async::Redis::Client
	
	let(:test_string) {"beep-boop"}
	let(:string_key) {root["string_key"]}
	
	it "can delete keys" do
		client.set(string_key, test_string)
		
		expect(client.del string_key).to be == 1
		expect(client.get string_key).to be_nil
	end

	let(:other_key) {root["other_key"]}

	it "can rename keys" do
		client.set(string_key, test_string)

		expect(client.rename string_key, other_key).to be == "OK"
		expect(client.get other_key).to be == test_string
		expect(client.get string_key).to be_nil

		client.set(string_key, test_string)

		expect(client.renamenx string_key, other_key).to be == 0
	end

	let(:whole_day) {24 * 60 * 60}
	let(:one_hour) {60 * 60}

	it "can modify and query the expiry of keys" do
		client.set string_key, test_string
		# make the key expire tomorrow
		client.expireat string_key, DateTime.now + 1

		ttl = client.ttl(string_key)
		expect(ttl).to be_within(10).of(whole_day)

		client.persist string_key
		expect(client.ttl string_key).to be == -1

		client.expire string_key, one_hour
		expect(client.ttl string_key).to be_within(10).of(one_hour)
	end

	it "can serialize and restore values" do
		client.set(string_key, test_string)
		serialized = client.dump string_key

		expect(client.restore other_key, serialized).to be == "OK"
		expect(client.get other_key).to be == test_string
	end
end
