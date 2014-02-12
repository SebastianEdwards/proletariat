module Proletariat
  module Testing
    # Internal: Executes a block and ensures given expectations are satisfied
    #           before continuing.
    class ExpectationGuarantor
      # Public: An error which will be raised if the expectation is not
      #         satisfied within the timeout.
      class MessageTimeoutError < RuntimeError; end

      # Public: Default time to wait for expectation to be satisfied.
      MESSAGE_TIMEOUT = 10

      # Public: Interval at which to check expectation is satisfied.
      MESSAGE_CHECK_INTERVAL = 0.2

      # Public: Creates a new ExpectationGuarantor instance.
      #
      # expectations - An Array of Expectations to be checked.
      # block        - The block of code within which the expectations should
      #                be satisfied.
      def initialize(expectations, &block)
        @counters    = []
        @subscribers = []

        expectations.each do |expectation|
          queue_config = generate_queue_config_for_topic(expectation.topics)
          counter = MessageCounter.new(expectation.quantity)
          counters << counter
          subscribers << Subscriber.new(counter, queue_config)
        end

        @block = block

        run_subscribers
      end

      # Public: Execute the blocks and waits for the expectations to be met.
      #
      # Returns nil if expectations are met within timeout.
      # Raises MessageTimeoutError if expectations are not met within timeout.
      def guarantee
        block.call if block

        timer = 0.0

        until passed?
          fail MessageTimeoutError if timer > MESSAGE_TIMEOUT
          sleep MESSAGE_CHECK_INTERVAL
          timer += MESSAGE_CHECK_INTERVAL
        end

        stop_subscribers

        nil
      end

      private

      # Internal: Returns the block of code in which the expectations should be
      #           satisfied.
      attr_reader :block

      # Internal: Returns an array of MessageCounter instances.
      attr_reader :counters

      # Internal: Returns an array of Subscriber instances.
      attr_reader :subscribers

      def generate_queue_config_for_topic(topics)
        QueueConfig.new('', topics, true)
      end

      # Internal: Checks each counter to ensure expected messages have arrived.
      #
      # Returns true if all counters are satisfied.
      # Returns false if one or more counters are not satisfied.
      def passed?
        counters
          .map(&:expected_messages_received?)
          .reduce { |a, e| a && e }
      end

      # Internal: Starts each subscriber.
      #
      # Returns nil.
      def run_subscribers
        subscribers.each { |subscriber| subscriber.run! }

        nil
      end

      # Internal: Stops each subscriber.
      #
      # Returns nil.
      def stop_subscribers
        subscribers.each { |subscriber| subscriber.stop }

        nil
      end

      # Internal: Counts incoming messages to test expection satisfaction.
      class MessageCounter
        # Public: Creates a new MessageCounter instance.
        #
        # expected - The number of messages expected.
        def initialize(expected, count = 0)
          @count    = count
          @expected = expected
        end

        # Public: Checks whether message count satifies expected count.
        #
        # Returns true if count is greater or equal to expected.
        # Returns false if count less than expected.
        def expected_messages_received?
          count >= expected
        end

        # Public: Handles message calls from a subscriber and increments the
        #         count. Return value matches interface expected by Subscriber.
        #
        # message - The contents of the message.
        #
        # Returns a future-like object holding an :ok Symbol.
        def post?(message, routing_key)
          self.count = count + 1

          Concurrent::Future.new { :ok }
        end

        private

        # Internal: Returns the current message count.
        attr_accessor :count

        # Internal: Returns the expected message count.
        attr_reader :expected
      end
    end
  end
end
