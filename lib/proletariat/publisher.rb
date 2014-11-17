require 'proletariat/concerns/logging'

module Proletariat
  # Public: Receives messages and publishes them to a RabbitMQ topic exchange.
  class Publisher < PoolableActor
    include Concerns::Logging

    # Public: Closes the Bunny::Channel if open.
    #
    # Returns nil.
    def cleanup
      @channel.close if @channel

      nil
    end

    # Public: Push a Message to a RabbitMQ topic exchange.
    #
    # message - A Message to send.
    #
    # Returns nil.
    def work(message)
      if message.is_a?(Message)
        exchange.publish(message.body, routing_key: message.to,
                                       persistent: !Proletariat.test_mode?,
                                       headers: message.headers)
      end
    end

    private

    # Internal: Returns the Bunny::Channel in use.
    def channel
      @channel ||= Proletariat.connection.create_channel
    end

    # Internal: Returns the Bunny::Exchange in use.
    def exchange
      @exchange ||= channel.topic(Proletariat.exchange_name,
                                  durable: !Proletariat.test_mode?)
    end
  end
end
