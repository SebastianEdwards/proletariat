module Proletariat
  # Internal: Exception handler with an exponential back-off strategy. Uses
  #           dead-letter queues.
  class ExponentialBackoff < ExceptionHandler
    # Public: Called on actor termination. Used to stop consumption off the
    #         requeue queue and close the channel.
    #
    # Returns nil.
    def cleanup
      @consumer.cancel if @consumer
      @channel.close if @channel && channel.open?
    end

    # Public: Callback hook for initialization. Kicks off the queue setup.
    def setup
      setup_requeue_queue
      consume_requeue
      setup_retry_queues
    end

    # Public: Puts messages into a delay queue to be retried in the future.
    #
    # body        - The failed message body.
    # to          - The failed message's routing key.
    # headers     - The failed message's headers.
    #
    # Returns nil.
    def work(message, to, headers)
      failures = queue_for_x_death(headers['x-death'])

      exchange.publish(message,
                       routing_key: "#{queue_name}_delay_#{failures}",
                       persistent: !Proletariat.test_mode?,
                       headers: headers.merge('proletariat-to' => to))

      nil
    end

    private

    # Internal: Returns the Bunny::Channel in use.
    def channel
      @channel ||= Proletariat.connection.create_channel
    end

    # Internal: Starts a consumer on the requeue queue which puts messages back
    #           onto the main queue.
    #
    # Returns nil.
    def consume_requeue
      @consumer = @requeue.subscribe do |info, props, body|
        Proletariat.publish(props.headers['proletariat-to'], body,
                            props.headers)

        nil
      end
    end

    # Internal: Returns the Bunny::Exchange in use.
    def exchange
      @exchange ||= channel.direct(exchange_name,
                                   durable: !Proletariat.test_mode?,
                                   auto_delete: Proletariat.test_mode?)
    end

    # Internal: Returns a new exchange name for a direct exchange.
    def exchange_name
      "#{Proletariat.exchange_name}_retry"
    end

    # Internal: Determines which delay queue a failed message should go in
    #           based on number of past fails shown in x-death header.
    #
    # header - the x-death header.
    #
    # Returns an Integer.
    def queue_for_x_death(header)
      if header
        [header.length, retry_delay_times.length - 1].min
      else
        0
      end
    end

    # Internal: Calculates an exponential retry delay based on the previous
    #           number of failures. Capped with configuration setting.
    #
    # Returns the delay in seconds as a Fixnum.
    def retry_delay_times
      @delay_times ||= begin
        (1..Float::INFINITY)
          .lazy
          .map { |i| i**i }
          .take_while { |i| i < Proletariat.max_retry_delay }
          .to_a
          .push(Proletariat.max_retry_delay)
          .map { |seconds| seconds * 1000 }
      end
    end

    # Internal: Creates the requeue queue and binds it to the exchange.
    def setup_requeue_queue
      @requeue = channel.queue("#{queue_name}_requeue",
                               durable: !Proletariat.test_mode?,
                               auto_delete: Proletariat.test_mode?)

      @requeue.bind(exchange, routing_key: "#{queue_name}_requeue")
    end

    # Internal: Create a delay queue and binds it to the exchange.
    def setup_retry_queue(delay, index)
      channel.queue("#{queue_name}_delay_#{index}",
                    durable: !Proletariat.test_mode?,
                    auto_delete: Proletariat.test_mode?,
                    arguments: {
                      'x-dead-letter-exchange' => exchange_name,
                      'x-dead-letter-routing-key' => "#{queue_name}_requeue",
                      'x-message-ttl' => delay
                    }
      ).bind(exchange, routing_key: "#{queue_name}_delay_#{index}")
    end

    # Internal: Creates the delay queues based on the max retry time.
    def setup_retry_queues
      retry_delay_times.each_with_index.map do |delay, index|
        setup_retry_queue(delay, index)
      end
    end
  end
end
