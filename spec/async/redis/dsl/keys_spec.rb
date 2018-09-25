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
require_relative '../database_cleanup'

RSpec.describe Async::Redis::DSL::Keys, timeout: 5 do
	include_context Async::RSpec::Reactor
	include_context "database cleanup"

	let(:endpoint) {Async::Redis.local_endpoint}
	let(:client) {Async::Redis::Client.new(endpoint)}

	let(:test_string) {"beep-boop"}
	let(:prefix) {"async-redis:test:"}
	let(:string_key) {"async-redis:test:string_key"}
	
	it "can delete keys" do
		client.set(string_key, test_string)
		
		expect(client.del string_key).to be == 1
		expect(client.get string_key).to be_nil

		client.close()
	end

	let(:other_key) {"other_key"}

	it "can rename keys" do
		client.set(string_key, test_string)

		expect(client.rename string_key, other_key).to be == "OK"
		expect(client.get other_key).to be == test_string
		expect(client.get string_key).to be_nil

		client.set(string_key, test_string)

		expect(client.renamenx string_key, other_key).to be == 0

		client.close
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

		client.close
	end

	it "can serialize and restore values" do
		client.set(string_key, test_string)
		serialized = client.dump string_key

		expect(client.restore other_key, serialized).to be == "OK"
		expect(client.get other_key).to be == test_string

		client.close
	end

	let(:test_data) do
		keys = %w[a b c d e]
		pairs = Hash.new
		keys.each do |k|
			pairs['async-redis:test:' + k] = k
		end
		pairs
	end

	it "can pick a random key" do
		client.mset test_data
		expect(test_data.keys).to include(client.randomkey)
		client.close
	end
end
