module Proletariat
  module Testing
    # Internal: Defines a quantity of messages you expect to receive on a set
    #         of topics.
    class Expectation < Struct.new(:topics, :quantity)
      # Public: Builds a new duplicate of current instance with different
      #         topics.
      #
      # Returns a new instance of Expectation.
      def on_topic(*topics)
        Expectation.new(topics, quantity)
      end
    end
  end
end
