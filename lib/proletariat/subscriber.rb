module Proletariat
  # Internal: Creates, binds and listens on a RabbitMQ queue. Forwards
  #           messages to a given listener.
  class Subscriber
    include Concurrent::Runnable

    include Concerns::Logging

    # Public: Creates a new Subscriber instance.
    #
    # connection    - An open Bunny::Session object.
    # exchange_name - A String of the RabbitMQ topic exchange.
    # queue_config  - A QueueConfig value object.
    def initialize(listener, queue_config)
      @listener     = listener
      @queue_config = queue_config

      @channel      = Proletariat.connection.create_channel

      @channel.prefetch Proletariat.worker_threads

      @exchange     = @channel.topic Proletariat.exchange_name, durable: true
      @bunny_queue  = @channel.queue queue_config.queue_name,
                                     durable: true,
                                     auto_delete: queue_config.auto_delete

      bind_queue
    end

    # Internal: Called by the Concurrent framework on run. Used here to start
    #           consumption of the queue and to log the status of the
    #           subscriber.
    #
    # Returns nil.
    def on_run
      start_consumer
      log_info 'Now online'

      nil
    end

    # Internal: Called by the Concurrent framework on run. Used here to stop
    #           consumption of the queue and to log the status of the
    #           subscriber.
    #
    # Returns nil.
    def on_stop
      log_info 'Attempting graceful shutdown.'
      stop_consumer
      log_info 'Now offline'
    end

    # Internal: Called by the Concurrent framework to perform work. Used here
    #           acknowledge RabbitMQ messages.
    #
    # Returns nil.
    def on_task
      ready_acknowledgers.each do |acknowledger|
        acknowledger.acknowledge_on_channel channel
        acknowledgers.delete acknowledger
      end
    end

    # Public: Purge the RabbitMQ queue.
    #
    # Returns nil.
    def purge
      bunny_queue.purge

      nil
    end

    private

    # Internal: Returns the Bunny::Queue in use.
    attr_reader :bunny_queue

    # Internal: Returns the Bunny::Channel in use.
    attr_reader :channel

    # Internal: Returns the Bunny::Exchange in use.
    attr_reader :exchange

    # Internal: Returns the listener object.
    attr_reader :listener

    # Internal: Returns the queue_config in use.
    attr_reader :queue_config

    def acknowledgers
      @acknowledgers ||= []
    end

    # Internal: Binds bunny_queue to the exchange via each routing key
    #           specified in the queue_config.
    #
    # Returns nil.
    def bind_queue
      queue_config.routing_keys.each do |key|
        bunny_queue.bind exchange, routing_key: key
      end

      nil
    end

    # Internal: Get acknowledgers for messages whose work has completed.
    #
    # Returns an Array of Acknowledgers.
    def ready_acknowledgers
      acknowledgers.select do |acknowledger|
        acknowledger.ready_to_acknowledge?
      end
    end

    # Internal: Starts a consumer on the queue. The consumer forwards all
    #           message bodies to listener#post.
    #
    # Returns nil.
    def start_consumer
      @consumer = bunny_queue.subscribe ack: true do |info, properties, body|
        future = listener.post?(body)
        acknowledgers << Acknowledger.new(future, info.delivery_tag)

        nil
      end

      nil
    end

    # Internal: Stops any active consumer. Waits for acknowledgement queue to
    #           drain before returning.
    #
    # Returns nil.
    def stop_consumer
      @consumer.cancel if @consumer
      wait_for_acknowledgers if acknowledgers.any?

      nil
    end

    # Internal: Makes blocking calls for each unacknowledged message until all
    #           messages are acknowledged.
    #
    # Returns nil.
    def wait_for_acknowledgers
      log_info 'Waiting for unacknowledged messages.'
      while acknowledgers.any?
        acknowledger = acknowledgers.pop
        acknowledger.block_until_acknowledged channel
      end

      nil
    end

    # Internal: Used to watch the state of dispatched Work and send ack/nack
    #           to a RabbitMQ channel.
    class Acknowledger
      # Public: Maximum time in seconds to wait synchronously for an
      #         acknowledgement.
      MAX_BLOCK_TIME = 5

      # Public: Creates a new Acknowledger instance.
      #
      # future       - A future-like object holding the Worker response.
      # delivery_tag - The RabbitMQ delivery tag to be used when ack/nacking.
      def initialize(future, delivery_tag)
        @future       = future
        @delivery_tag = delivery_tag
      end

      # Public: Retrieves the value from the future and sends the relevant
      #         acknowledgement on a given channel. Logs a warning if the
      #         future value is unexpected.
      #
      # channel - The Bunny::Channel to receive the acknowledgement.
      #
      # Returns nil.
      def acknowledge_on_channel(channel)
        if future.fulfilled?
          acknowledge_success(channel)
        elsif future.rejected?
          acknowledge_error(channel)
        end

        nil
      end

      # Public: Blocks until acknowledgement completes.
      #
      # channel - The Bunny::Channel to receive the acknowledgement.
      #
      # Returns nil.
      def block_until_acknowledged(channel)
        future.value(MAX_BLOCK_TIME)
        acknowledge_on_channel(channel)

        nil
      end

      # Public: Gets the readiness of the future for acknowledgement use.
      #
      # Returns true if future is fulfilled or rejected.
      def ready_to_acknowledge?
        future.state != :pending
      end

      private

      # Internal: Dispatches acknowledgements for non-errored worker responses.
      #           Maps symbol value to acknowledgement strategies.
      #
      # channel - The Bunny::Channel to receive the acknowledgement.
      #
      # Returns nil.
      def acknowledge_success(channel)
        case future.value
        when :ok then channel.acknowledge delivery_tag
        when :drop then channel.reject delivery_tag, false
        when :requeue then channel.reject delivery_tag, true
        else
          Proletariat.logger.warn 'Unexpected return value from #work.'
          channel.reject delivery_tag, false
        end

        nil
      end

      # Internal: Dispatches acknowledgements for errored worker responses.
      #           Requeues messages and logs the error.
      #
      # channel - The Bunny::Channel to receive the acknowledgement.
      #
      # Returns nil.
      def acknowledge_error(channel)
        Proletariat.logger.error future.reason
        channel.reject delivery_tag, true

        nil
      end

      # Internal: Returns the RabbitMQ delivery tag.
      attr_reader :delivery_tag

      # Internal: Returns the future-like object holding the Worker response.
      attr_reader :future
    end
  end
end
