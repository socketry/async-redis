require 'async/redis/client'

RSpec.describe Async::Redis::Context::Psubscribe, timeout: 5 do
  include_context Async::RSpec::Reactor

  let(:endpoint) {Async::Redis.local_endpoint}
  let(:client) {Async::Redis::Client.new(endpoint)}

  it "should subscribe to channels using pattern" do
    condition = Async::Condition.new

    publisher = reactor.async do
      condition.wait
      Async.logger.debug("Publishing message...")
      client.publish 'news.breaking', 'AAA'
    end

    listener = reactor.async do
      Async.logger.debug("Subscribing...")
      client.psubscribe 'news.*' do |context|
        Async.logger.debug("Waiting for message...")
        condition.signal

        type, pattern, name, message = context.listen

        Async.logger.debug("Got: #{type} #{name} #{message}")
        expect(type).to be == 'pmessage'
        expect(pattern).to be == 'news.*'
        expect(name).to be == 'news.breaking'
        expect(message).to be == 'AAA'
      end
    end

    publisher.wait
    listener.wait

    client.close
  end
end
