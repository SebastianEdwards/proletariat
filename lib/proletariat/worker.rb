module Proletariat
  # Public: Handles messages from a RabbitMQ queue. Subclasses should
  #         overwrite the #work method.
  class Worker < Concurrent::Actor
    include Concerns::Logging

    # Internal: Called by the Concurrent framework to handle new mailbox
    #           messages. Overridden in this subclass to call the #work method
    #           with the given message.
    #
    # message - The incoming message.
    #
    # Returns nil.
    def act(message)
      work message
    end

    # Internal: Called by the Concurrent framework on actor start. Overridden
    #           in this subclass to log the status of the worker.
    #
    # Returns nil.
    def on_run
      super

      log_info 'Now online'

      nil
    end

    # Internal: Called by the Concurrent framework on actor start. Overridden
    #         in this subclass to log the status of the worker.
    #
    # Returns nil.
    def on_stop
      log_info 'Attempting graceful shutdown.'
      wait_for_work_queue unless queue.empty?

      super

      log_info 'Now offline'

      nil
    end

    # Public: Handles RabbitMQ messages.
    #
    # message - The incoming message.
    #
    # Raises NotImplementedError unless implemented in subclass.
    def work(message)
      fail NotImplementedError
    end

    protected

    # Public: Helper method to ease accessing the logger from within #work.
    #         Sends #info to logger if message provided.
    #
    # Examples
    #
    #   log 'Background Workers Unite!'
    #   # Message is logged at info level.
    #
    #   log.error 'Something bad happened!'
    #   # Message is logged at error level.
    #
    # Returns the process-wide logger if message not supplied.
    # Returns nil if message supplied.
    def log(message = nil)
      if message
        Proletariat.logger.info(message)

        nil
      else
        Proletariat.logger
      end
    end

    # Public: Helper method to ease sending messages from within #work.
    #
    # to      - The routing key for the message to as a String. In accordance
    #           with the RabbitMQ convention you can use the '*' character to
    #           replace one word and the '#' to replace many words.
    # message - The message as a String.
    #
    # Returns nil.
    def publish(to, message = '')
      Proletariat.publish to, message

      nil
    end

    private

    # Internal: Blocks until each message has been handled by #work.
    #
    # Returns nil.
    def wait_for_work_queue
      log_info 'Waiting for work queue to drain.'

      work(*queue.pop.message) until queue.empty?

      nil
    end

    # Internal: Class methods on Worker to provide configuration DSL.
    module ConfigurationMethods
      # Public: A configuration method for adding a routing key to be used when
      #         binding this worker type's queue to an exchange.
      #
      # routing_key - A routing key for queue-binding as a String.
      #
      # Returns nil.
      def listen_on(routing_key)
        routing_keys << routing_key

        nil
      end

      # Internal: Returns the list of all desired routing keys for this worker
      #           type
      #
      # Returns an Array of routing keys as Strings.
      def routing_keys
        @routing_keys ||= []
      end
    end

    extend ConfigurationMethods
  end
end
