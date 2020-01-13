require_relative 'generic'

module Async
  module Redis
    module Context
      class Psubscribe < Generic
        def initialize(pool, channels)
          super(pool)

          @channels = channels

          psubscribe(channels)
        end

        def listen
          return @connection.read_response
        end

        private

        def psubscribe(channels)
          @connection.write_request ['PSUBSCRIBE', *channels]
          @connection.flush

          response = nil

          channels.length.times do |i|
            response = @connection.read_response
          end

          return response
        end
      end
    end
  end
end
