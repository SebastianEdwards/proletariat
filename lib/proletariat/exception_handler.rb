require 'proletariat/concerns/logging'

module Proletariat
  # Public: Handles messages whose work raised an exception. Should overwrite
  #         the #work method to implement retry/drop logic.
  class ExceptionHandler < Actor
    include Concerns::Logging

    def initialize(queue_name)
      @queue_name = queue_name
      setup
    end

    # Internal: Handles the Actor mailbox. Delegates work to #work.
    #
    # message - A Message to send.
    def actor_work(message)
      work message.body, message.to, message.headers if message.is_a?(Message)
    end

    # Public: Callback hook for initialization.
    def setup
    end

    # Public: Handles an incoming message to perform background work.
    #
    # body        - The failed message body.
    # to          - The failed message's routing key.
    # headers     - The failed message's headers.
    #
    # Raises NotImplementedError unless implemented in subclass.
    def work(body, to, headers)
      fail NotImplementedError
    end

    # Public: Use #actor_work to handle the actor mailbox.
    def work_method
      :actor_work
    end

    protected

    attr_reader :queue_name
  end
end
