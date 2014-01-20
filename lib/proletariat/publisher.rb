require 'proletariat/concerns/logging'

module Proletariat
  # Public: Receives messages and publishes them to a RabbitMQ topic exchange.
  class Publisher
    include Concerns::Logging

    # Public: Creates a new Publisher instance.
    #
    # connection    - An open Bunny::Session object.
    # exchange_name - A String of the RabbitMQ topic exchange.
    def initialize
      @channel  = Proletariat.connection.create_channel
      @exchange = channel.topic(Proletariat.exchange_name, durable: true)
    end

    # Public: Logs the 'online' status of the publisher.
    #
    # Returns nil.
    def started
      log_info 'Now online'

      nil
    end

    # Public: Logs the 'offline' status of the publisher.
    #
    # Returns nil.
    def stopped
      log_info 'Now offline'

      nil
    end

    # Public: Logs the 'shutting down' status of the publisher.
    #
    # Returns nil.
    def stopping
      log_info 'Attempting graceful shutdown.'

      nil
    end

    # Public: Push a message to a RabbitMQ topic exchange.
    #
    # to      - The routing key for the message to as a String. In accordance
    #           with the RabbitMQ convention you can use the '*' character to
    #           replace one word and the '#' to replace many words.
    # message - The message as a String.
    #
    # Returns nil.
    def work(to, message)
      exchange.publish message, routing_key: to, persistent: true

      nil
    end

    private

    # Internal: Returns the Bunny::Channel in use.
    attr_reader :channel

    # Internal: Returns the Bunny::Exchange in use.
    attr_reader :exchange
  end
end
