# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2025, by Samuel Williams.

require "client_context"

describe Protocol::Redis::Methods::Strings do
	include_context ClientContext
	
	let(:string_key) {root["my_string"]}
	let(:other_string_key) {root["other_string"]}
	let(:test_string) {"beep-boop"}
	let(:other_string) {"doot"}

	it "can perform string manipulation" do
		expect(client.set(string_key, test_string)).to be == "OK"
		expect(client.get(string_key)).to be == test_string
		expect(client.strlen(string_key)).to be == test_string.length

		expect(client.setrange(string_key, 5, "beep")).to be == test_string.length
		expect(client.getrange(string_key, 5, 8)).to be == "beep"

		expect(client.append(string_key, "-boop")).to be == "beep-beep-boop".length
		expect(client.get(string_key)).to be == "beep-beep-boop"

		expect(client.getset(string_key, test_string)).to be == "beep-beep-boop"
		expect(client.get(string_key)).to be == test_string
	end

	it "can conditionally set values based on whether they exist or not" do
		expect(client.set(string_key, test_string)).to be == "OK"

		# only set if it doesn't exist, which it does already
		expect(client.setnx(string_key, other_string)).to be == false
		expect(client.get(string_key)).to be == test_string

		# only set if it exists, which it doesn't yet
		expect(client.set other_string_key, other_string, update: true).to be_nil
		expect(client.get other_string_key).to be_nil

		# only set if it doesn't exist, which it doesn't
		expect(client.setnx(other_string_key, test_string)).to be == true
		expect(client.get(other_string_key)).to be == test_string

		# only set if it exists, which it does
		expect(client.set other_string_key, other_string, update: true).to be == "OK"
		expect(client.get other_string_key).to be == other_string
	end

	let(:seconds) {3}
	let(:milliseconds) {3500}

	it "can set values with a time-to-live" do
		expect(client.set(string_key, test_string)).to be == "OK"
		expect(client.call("TTL", string_key)).to be == -1

		expect(client.setex(string_key, seconds, test_string)).to be == "OK"
		expect(client.call("TTL", string_key)).to be >= 0

		expect(client.psetex(other_string_key, milliseconds, other_string)).to be == "OK"
		expect(client.call("TTL", other_string_key)).to be >= 0

		expect{
			client.set string_key, test_string, seconds: seconds, milliseconds: milliseconds
		}.to raise_exception(Async::Redis::ServerError)
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
	end

	let(:float_key) {"async-redis:test:float"}
	let(:test_float) {554.4}

	it "can perform manipulations on string representation of floats" do
		expect(client.set(float_key, test_float)).to be == "OK"
		
		expect(client.incrbyfloat(float_key, 1.1)).to be == "555.5"
	end

	let(:test_pairs) do
		{
			root["key_a"] => "a",
			root["key_b"] => "b",
			root["key_c"] => "c"
		}
	end

	let(:overlapping_pairs) do
		{
			root["key_a"] => "x",
			root["key_d"] => "y",
			root["key_e"] => "z",
		}
	end

	let(:disjoint_pairs) do
		{
			root["key_d"] => "d",
			root["key_e"] => "e",
		}
	end

	it "can set and get multiple key value pairs" do
		expect(client.mset(test_pairs)).to be == "OK"
		expect(client.mget(*test_pairs.keys)).to be == test_pairs.values

		expect(client.msetnx(overlapping_pairs)).to be == 0
		expect(client.mget(*test_pairs.keys)).to be == test_pairs.values

		expect(client.msetnx(disjoint_pairs)).to be == 1
		expect(client.mget(*disjoint_pairs.keys)).to be == disjoint_pairs.values
	end
end
