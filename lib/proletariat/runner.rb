module Proletariat
  # Public: Sets up a supervisor which maintains a single Publisher and a
  # per-worker Manager instance.
  class Runner
    extend Forwardable

    # Public: Delegate lifecycle calls to the supervisor.
    def_delegators :supervisor, :run, :run!, :stop, :running?

    # Public: Creates a new Runner instance.
    def initialize
      @supervisor = Concurrent::Supervisor.new
      @managers   = []

      create_publisher_pool

      add_publishers_to_supervisor
      add_workers_to_supervisor
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
      publishers_mailbox.post to, message

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

    # Internal: Returns the pool of initialized publishers.
    attr_reader :publisher_pool

    # Internal: Returns a shared mailbox for the pool of publishers.
    attr_reader :publishers_mailbox

    # Internal: Returns the supervisor instance.
    attr_reader :supervisor

    # Internal: Adds each publisher in the publisher_pool to the supervisor.
    #
    # Returns nil.
    def add_publishers_to_supervisor
      publisher_pool.each { |publisher| supervisor.add_worker publisher }

      nil
    end

    # Internal: Creates a Manager per worker_class and adds these to the
    #           supervisor.
    #
    # Returns nil.
    def add_workers_to_supervisor
      Proletariat.worker_classes.each do |worker_class|
        manager = Manager.new(worker_class)
        @managers << manager
        supervisor.add_worker manager
      end

      nil
    end

    # Internal: Assign new Concurrent::Poolbox and Array[Publisher] to the
    #           manager's publishers_mailbox and publisher_pool properties
    #           respectively.
    #
    # Returns nil.
    def create_publisher_pool
      threads = Proletariat.publisher_threads
      @publishers_mailbox, @publisher_pool = Actor.pool(threads, Publisher)
    end
  end
end
