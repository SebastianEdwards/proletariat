require 'proletariat/concerns/logging'

module Proletariat
  # Public: Handles messages for Background processing. Subclasses should
  #         overwrite the #work method.
  class Worker < PoolableActor
    include Concerns::Logging

    # Internal: Handles the Actor mailbox. Delegates work to #work.
    #
    # message - A Message to send.
    def actor_work(message)
      work message.body, message.to, message.headers if message.is_a?(Message)
    end

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
    # headers - Hash of message headers.
    #
    # Returns nil.
    def publish(to, message = '', headers = {})
      log "Publishing to: #{to}"
      Proletariat.publish to, message, headers

      nil
    end

    # Public: Logs the 'online' status of the worker.
    #
    # Returns nil.
    def started
      log_info 'Now online'

      nil
    end

    # Public: Logs the 'offline' status of the worker.
    #
    # Returns nil.
    def stopped
      log_info 'Now offline'

      nil
    end

    # Public: Handles an incoming message to perform background work.
    #
    # message     - The incoming message.
    # routing_key - The incoming message's routing key.
    # headers     - The incoming message's headers.
    #
    # Raises NotImplementedError unless implemented in subclass.
    def work(message, routing_key, headers)
      fail NotImplementedError
    end

    # Public: Use #actor_work to handle the actor mailbox.
    def work_method
      :actor_work
    end

    # Internal: Class methods on Worker to provide configuration DSL.
    module ConfigurationMethods
      def exception_handler(value = nil)
        if value
          @exception_handler = value
        else
          @exception_handler || :exponential_backoff
        end
      end

      # Public: A configuration method for adding a routing key to be used when
      #         binding this worker type's queue to an exchange.
      #
      # routing_key - A routing key for queue-binding as a String.
      #
      # Returns nil.
      def listen_on(*new_routing_keys)
        routing_keys.concat new_routing_keys

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
