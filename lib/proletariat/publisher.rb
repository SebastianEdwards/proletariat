module Proletariat
  # Public: Listens for messages in it's mailbox and publishes
  #         these to a RabbitMQ topic exchange.
  class Publisher < Concurrent::Actor
    include Concerns::Logging

    # Public: Creates a new Publisher instance.
    #
    # connection    - An open Bunny::Session object.
    # exchange_name - A String of the RabbitMQ topic exchange.
    def initialize(connection, exchange_name)
      @channel  = connection.create_channel
      @exchange = channel.topic(exchange_name, durable: true)
    end

    # Public: Called by the Concurrent framework to handle new mailbox
    #         messages. Overridden in this subclass to push messages to a
    #         RabbitMQ topic exchange.
    #
    # to      - The routing key for the message to as a String. In accordance
    #           with the RabbitMQ convention you can use the '*' character to
    #           replace one word and the '#' to replace many words.
    # message - The message as a String.
    #
    # Returns nil.
    def act(to, message)
      publish(to, message)

      nil
    end

    # Public: Called by the Concurrent framework on actor start. Overridden in
    #         this subclass to log the status of the publisher.
    #
    # Returns nil.
    def on_run
      super
      log_info 'Now online'

      nil
    end

    # Public: Called by the Concurrent framework on actor stop. Overridden in
    #         this subclass to log the status of the publisher.
    def on_stop
      log_info 'Attempting graceful shutdown.'
      wait_for_publish_queue unless queue.empty?

      super

      log_info 'Now offline'

      nil
    end

    private

    # Internal: Returns the Bunny::Channel in use.
    attr_reader :channel

    # Internal: Returns the Bunny::Exchange in use.
    attr_reader :exchange

    # Internal: Handles the actual message send to the exchange.
    #
    # to      - The routing key.
    # message - The message as a String.
    #
    # Returns nil.
    def publish(to, message)
      exchange.publish message, routing_key: to, persistent: true

      nil
    end

    # Internal: Blocks until each message has been published.
    #
    # Returns nil.
    def wait_for_publish_queue
      log_info 'Waiting for work queue to drain.'

      publish(*queue.pop.message) until queue.empty?

      nil
    end
  end
end
