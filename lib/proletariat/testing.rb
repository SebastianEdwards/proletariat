require 'proletariat/testing/expectation'
require 'proletariat/testing/expectation_guarantor'
require 'proletariat/testing/fixnum_extension'

module Proletariat
  # Public: Mixin to aid solve test synchronization issues while still running
  #         Proletariat the same way you would in production,
  module Testing
    # Public: Builds an Expectation instance which listens for a single message
    #         on any topic.
    #
    # Returns a new Expectation instance.
    def message
      Proletariat::Testing::Expectation.new(['#'], 1)
    end

    # Public: Creates and runs a new ExpectationGuarantor from a given list of
    #         Expectation instances and a block.
    #
    # expectations - One or more Expectation instances.
    # block        - A block within which the expectations should be
    #                satisfied.
    #
    # Examples
    #
    #   wait_for 3.messages.on_topic 'email_sent'
    #   # ... [Time passes]
    #   # => 'nil'
    #
    #   wait_for message.on_topic 'hell_freezes_over'
    #   # ... [Time passes]
    #   # => MessageTimeoutError
    #
    # Returns nil.
    def wait_for(*expectations, &block)
      ExpectationGuarantor.new(expectations, &block).guarantee

      nil
    end
  end
end
