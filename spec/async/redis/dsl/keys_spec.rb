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
	let(:string_key) {"async-redis:test:string_key"}
	
	it "can delete keys" do
		client.set(string_key, test_string)
		
		expect(client.del string_key).to be == 1

		client.close()
	end

	it "can rename keys" do

	end

	it "can modify and query the expiry of keys" do

	end

	it "can serialize and restore values" do

	end

	it "can pick a random key" do

	end
end
