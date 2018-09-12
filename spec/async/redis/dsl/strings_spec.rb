# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# and Huba Nagy
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

require 'async/redis/client'

RSpec.describe Async::Redis::DSL::Strings, timeout: 5 do
	include_context Async::RSpec::Reactor

	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}
	
	let(:string_key) {"async-redis:test:string"}
	let(:other_string_key) {"async-redis:test:other_string"}
	let(:test_string) {"beep-boop"}

	it "can perform string manipulation" do
		# This is a bit of a hack, there's no way to put this into
		# a before(:all) context, it is needed for testing SETNX
		client.call 'FLUSHDB'

		expect(client.set(string_key, test_string)).to be == "OK"
		expect(client.get(string_key)).to be == test_string
		expect(client.strlen(string_key)).to be == test_string.length

		expect(client.setrange(string_key, 5, "beep")).to be == test_string.length
		expect(client.getrange(string_key, 5, 8)).to be == "beep"

		expect(client.append(string_key, "-boop")).to be == "beep-beep-boop".length
		expect(client.get(string_key)).to be == "beep-beep-boop"

		expect(client.setnx(string_key, test_string)).to be == 0
		expect(client.get(string_key)).to be == "beep-beep-boop"

		expect(client.getset(string_key, test_string)).to be == "beep-beep-boop"
		expect(client.get(string_key)).to be == test_string

		expect(client.setnx(other_string_key, test_string)).to be == 1
		expect(client.get(other_string_key)).to be == test_string

		client.close
	end

	let(:integer_key) {"async-redis:test:integer"}
	let(:test_integer) {555}

	it "can perform manipulations on string representation of integers" do
		expect(client.set(integer_key, test_integer)).to be == "OK"
		expect(client.get(integer_key)).to be == "#{test_integer}"

		expect(client.incr(integer_key)).to be == test_integer + 1
		expect(client.decr(integer_key)).to be == test_integer

		expect(client.incrby(integer_key, 5)).to be == test_integer + 5
		expect(client.decrby(integer_key, 5)).to be == test_integer

		client.close
	end

	let(:float_key) {"async-redis:test:float"}
	let(:test_float) {554.4}

	it "can perform manipulations on string representation of floats" do
		expect(client.set(float_key, test_float)).to be == "OK"
		
		expect(client.incrbyfloat(float_key, 1.1)).to be == "555.5"

		client.close
	end

	let(:test_pairs) do
		{
			:'async-redis:test:key_a' => "a",
			:'async-redis:test:key_b' => "b",
			:'async-redis:test:key_c' => "c"
		}
	end

	let(:overlapping_pairs) do
		{
			:'async-redis:test:key_a' => "x",
			:'async-redis:test:key_d' => "y",
			:'async-redis:test:key_e' => "z",
		}
	end

	let(:disjoint_pairs) do
		{
			:'async-redis:test:key_d' => "d",
			:'async-redis:test:key_e' => "e",
		}
	end

	it "can set and get multiple key value pairs" do
		expect(client.mset(test_pairs)).to be == "OK"
		expect(client.mget(*test_pairs.keys)).to be == test_pairs.values

		expect(client.msetnx(overlapping_pairs)).to be == 0
		expect(client.mget(*test_pairs.keys)).to be == test_pairs.values

		expect(client.msetnx(disjoint_pairs)).to be == 1
		expect(client.mget(*disjoint_pairs.keys)).to be == disjoint_pairs.values

		client.close
	end
end
