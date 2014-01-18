module Proletariat
  # Public: Interface abstraction for Concurrent::Actor. Creates a delegate
  #         instance from given class and arguments and delegates events to it.
  class Actor < Concurrent::Actor
    # Public: Creates a new Actor instance.
    #
    # delegate_class - The class to instantiate as a delegate.
    # *arguments     - The arguments to pass to delegate_class.new
    def initialize(delegate_class, *arguments)
      @delegate = delegate_class.new(*arguments)
    end

    # Internal: Called by the Concurrent framework to handle new mailbox
    #           messages. Overridden in this subclass to call the #work method
    #           with the given arguments on the delegate.
    #
    # *arguments - The arguments to pass to delegate#work
    #
    # Returns nil.
    def act(*arguments)
      delegate.work(*arguments)
    end

    # Internal: Called by the Concurrent framework on actor start. Overridden
    #           in this subclass to call the #starting and #started methods on
    #           the delegate.
    #
    # Returns nil.
    def on_run
      delegate.starting if delegate.respond_to?(:starting)

      super

      delegate.started if delegate.respond_to?(:started)

      nil
    end

    # Internal: Called by the Concurrent framework on actor start. Overridden
    #           in this subclass to call the #stopping and #stopped methods on
    #           the delegate. Ensures queue is drained before calling #stopped.
    #
    # Returns nil.
    def on_stop
      delegate.stopping if delegate.respond_to?(:stopping)

      wait_for_queue_to_drain unless queue.empty?

      super

      delegate.stopped if delegate.respond_to?(:stopped)

      nil
    end

    private

    # Internal: Returns the delegate instance.
    attr_reader :delegate

    # Internal: Blocks until each queued message has been handled by the
    #           delegate #work method.
    #
    # Returns nil.
    def wait_for_queue_to_drain
      delegate.work(*queue.pop.message) until queue.empty?

      nil
    end
  end
end
