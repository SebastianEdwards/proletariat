module Proletariat
  # Public: Sets up a supervisor which maintains a single Publisher and a
  # per-worker Manager instance.
  class Runner
    extend Forwardable

    # Public: Delegate lifecycle calls to the supervisor.
    def_delegators :supervisor, :run, :run!, :stop, :running?

    # Public: Creates a new Runner instance.
    def initialize
      @supervisor = Supervisor.new
      @managers   = Proletariat.worker_classes.map do |worker_class|
        Manager.new(worker_class)
      end

      supervisor.supervise_pool('publishers', Proletariat.publisher_threads,
                                Publisher)
      managers.each { |manager| supervisor.add_supervisor manager }
    end

    # Public: Publishes a message to RabbitMQ via the publisher pool.
    #
    # to      - The routing key for the message to as a String. In accordance
    #           with the RabbitMQ convention you can use the '*' character to
    #           replace one word and the '#' to replace many words.
    # message - The message as a String.
    #
    # Returns nil.
    def publish(to, message)
      supervisor['publishers'].post to, message

      nil
    end

    # Public: Purge the RabbitMQ queues.
    #
    # Returns nil.
    def purge
      managers.each { |manager| manager.purge }

      nil
    end

    private

    # Internal: Returns an Array of the currently supervised Managers.
    attr_reader :managers

    # Internal: Returns the supervisor instance.
    attr_reader :supervisor
  end
end
