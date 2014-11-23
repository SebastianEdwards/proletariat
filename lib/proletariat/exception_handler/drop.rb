module Proletariat
  # Internal: Exception handler which just drops failed messages.
  class Drop < ExceptionHandler
    # Public: Does nothing with the failed messages.
    #
    # body        - The failed message body.
    # to          - The failed message's routing key.
    # headers     - The failed message's headers.
    #
    # Returns nil.
    def work(message, to, headers)
      nil
    end
  end
end
