# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018, by Huba Nagy.
# Copyright, 2018-2025, by Samuel Williams.

require "client_context"

describe Protocol::Redis::Methods::Generic do
	include_context ClientContext
	
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
