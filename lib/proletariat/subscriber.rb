module Proletariat
  # Internal: Creates, binds and listens on a RabbitMQ queue. Forwards
  #           messages to a given listener.
  class Subscriber < Actor
    include Concerns::Logging

    # Public: Creates a new Subscriber instance.
    #
    # listener     - Object to delegate new messages to.
    # queue_config - A QueueConfig value object.
    def initialize(listener, queue_config)
      @listener     = listener
      @queue_config = queue_config

      bind_queue
      start_consumer

      @ticker = Concurrent::TimerTask.execute(execution: 5, timeout: 2) do
        acknowledge_messages
        clear_retries
      end
    end

    # Internal: Called on actor termination. Used to stop consumption off the
    #           queue and end the ticker.
    #
    # Returns nil.
    def cleanup
      @ticker.kill   if @ticker
      stop_consumer  if @consumer
      @channel.close if @channel && channel.open?

      nil
    end

    private

    # Internal: Returns the listener object.
    attr_reader :listener

    # Internal: Returns the queue_config in use.
    attr_reader :queue_config

    # Internal: Acknowledge processed messages.
    #
    # Returns nil.
    def acknowledge_messages
      ready_acknowledgers.each do |acknowledger|
        acknowledger.acknowledge_on_channel channel
        acknowledgers.delete acknowledger
      end

      nil
    end

    # Internal: Returns array of Acknowledgers which haven't acknowledged their
    #           messages.
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

    # Internal: Returns the Bunny::Queue in use.
    def bunny_queue
      @bunny_queue ||= channel.queue(queue_config.queue_name,
                                     durable: !Proletariat.test_mode?,
                                     auto_delete: Proletariat.test_mode?)
    end

    # Internal: Clear out completed retries.
    #
    # Returns nil.
    def clear_retries
      completed_retries.each { |r| scheduled_retries.delete r }
    end

    # Internal: Returns the Bunny::Channel in use.
    def channel
      @channel ||= Proletariat.connection.create_channel.tap do |channel|
        channel.prefetch Proletariat.worker_threads + 1
      end
    end

    # Internal: Get scheduled retries whose messages have been requeued.
    #
    # Returns an Array of Retrys.
    def completed_retries
      scheduled_retries.select { |r| r.requeued? }
    end

    # Internal: Returns the Bunny::Exchange in use.
    def exchange
      @exchange ||= channel.topic(Proletariat.exchange_name,
                                  durable: !Proletariat.test_mode?)
    end

    # Internal: Forwards all message bodies to listener#post. Auto-acks
    #           messages not meant for this subscriber's workers.
    #
    # Returns nil.
    def handle_message(info, properties, body)
      if handles_worker_type? properties.headers['worker']
        message = Message.new(info.routing_key, body, properties.headers)
        ivar = listener.ask(message)
        acknowledgers << Acknowledger.new(ivar, info.delivery_tag, {
          message: body, key: info.routing_key, headers: properties.headers,
          worker:  queue_config.queue_name }, scheduled_retries)
      else
        channel.ack info.delivery_tag
      end

      nil
    end

    # Internal: Checks if subscriber should handle message for given worker
    #           header.
    #
    # Returns true if should be handled or header is nil.
    # Returns false if should not be handled.
    def handles_worker_type?(worker_header)
      [nil, queue_config.queue_name].include? worker_header
    end

    # Internal: Get acknowledgers for messages whose work has completed.
    #
    # Returns an Array of Acknowledgers.
    def ready_acknowledgers
      acknowledgers.select do |acknowledger|
        acknowledger.ready_to_acknowledge?
      end
    end

    def scheduled_retries
      @scheduled_retries ||= []
    end

    # Internal: Starts a consumer on the queue. The consumer forwards all
    #           message bodies to listener#post. Auto-acks messages not meant
    #           for this subscriber's workers.
    #
    # Returns nil.
    def start_consumer
      @consumer = bunny_queue.subscribe manual_ack: true do |info, props, body|
        acknowledge_messages
        clear_retries

        handle_message info, props, body

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
      scheduled_retries.each { |r| r.expedite }

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
      include Concerns::Logging

      # Public: Maximum time in seconds to wait synchronously for an
      #         acknowledgement.
      MAX_BLOCK_TIME = 5

      # Public: Creates a new Acknowledger instance.
      #
      # ivar              - A ivar-like object holding the Worker response.
      # delivery_tag      - The RabbitMQ delivery tag for ack/nacking.
      # properties        - The original message properties; for requeuing.
      # scheduled_retries - An Array to hold any created Retrys.
      def initialize(ivar, delivery_tag, properties, scheduled_retries)
        @ivar              = ivar
        @delivery_tag      = delivery_tag
        @properties        = properties
        @scheduled_retries = scheduled_retries
      end

      # Public: Retrieves the value from the ivar and sends the relevant
      #         acknowledgement on a given channel. Logs a warning if the
      #         ivar value is unexpected.
      #
      # channel - The Bunny::Channel to receive the acknowledgement.
      #
      # Returns nil.
      def acknowledge_on_channel(channel)
        if ivar.fulfilled?
          acknowledge_success(channel)
        elsif ivar.rejected?
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
        ivar.wait(MAX_BLOCK_TIME)
        acknowledge_on_channel(channel)

        nil
      end

      # Public: Gets the readiness of the ivar for acknowledgement use.
      #
      # Returns true if ivar is fulfilled or rejected.
      def ready_to_acknowledge?
        ivar.completed?
      end

      private

      # Internal: Dispatches acknowledgements for non-errored worker responses.
      #           Maps symbol value to acknowledgement strategies.
      #
      # channel - The Bunny::Channel to receive the acknowledgement.
      #
      # Returns nil.
      def acknowledge_success(channel)
        case ivar.value
        when :ok then channel.ack delivery_tag
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
        Proletariat.logger.error ivar.reason

        scheduled_retries << Retry.new(properties)
        channel.ack delivery_tag

        nil
      end

      # Internal: Returns the RabbitMQ delivery tag.
      attr_reader :delivery_tag

      # Internal: Returns the ivar-like object holding the Worker response.
      attr_reader :ivar

      # Internal: Returns the original message properties.
      attr_reader :properties

      # Internal: Returns the Array of Retrys.
      attr_reader :scheduled_retries

      # Internal: Used publish an exponential delayed requeue for failures.
      class Retry
        # Public: Creates a new Retry instance. Sets appropriate headers for
        #         requeue message.
        #
        # properties - The original message properties.
        def initialize(properties)
          @properties = properties

          properties[:headers]['failures'] = failures
          properties[:headers]['worker']   = properties[:worker]

          @scheduled_task = Concurrent::ScheduledTask.execute(retry_delay) do
            requeue_message
          end
        end

        # Public: Attempt to requeue the message immediately if pending or
        #         wait for natural completion.
        #
        # Returns nil.
        def expedite
          if scheduled_task.cancel
            requeue_message
          else
            scheduled_task.value
          end

          nil
        end

        # Public: Tests whether the message has been requeued.
        #
        # Returns a Boolean.
        def requeued?
          scheduled_task.fulfilled?
        end

        private

        # Internal: Returns the original message properties.
        attr_reader :properties

        # Internal: Returns the ScheduledTask which will requeue the message.
        attr_reader :scheduled_task

        # Internal: Fetches the current number of message failures from the
        #           headers. Defaults to 1.
        #
        # Returns a Fixnum.
        def failures
          @failures ||= (properties[:headers]['failures'] || 0) + 1
        end

        # Internal: Performs the actual message requeue.
        #
        # Returns nil.
        def requeue_message
          Proletariat.publish(properties[:key], properties[:message],
                              properties[:headers])

          nil
        end

        # Internal: Calculates an exponential retry delay based on the previous
        #           number of failures. Capped with configuration setting.
        #
        # Returns the delay in seconds as a Fixnum.
        def retry_delay
          [2**failures, Proletariat.max_retry_delay].min
        end
      end
    end
  end
end
