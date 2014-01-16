module Proletariat
  # Public: Sets up a supervisor which maintains a single Publisher and a
  # per-worker Manager instance.
  class Runner
    extend Forwardable

    # Public: Delegate lifecycle calls to the supervisor.
    def_delegators :supervisor, :run, :run!, :stop, :running?

    # Public: Returns an open Bunny::Session object.
    attr_reader :connection

    # Public: Returns the name of the RabbitMQ topic exchange.
    attr_reader :exchange_name

    # Public: Creates a new Runner instance. Default options should be fine for
    #         most scenarios.
    #
    # options - A Hash of options (default: {}):
    #             :connection        - An open RabbitMQ::Session object.
    #             :exchange_name     - The RabbitMQ topic exchange name as a
    #                                  String.
    #             :publisher_threads - The size of the publisher thread pool.
    #             :supervisor        - A Supervisor instance.
    #             :worker_classes    - An Array of Worker subclasses.
    #             :worker_threads    - The size of the worker thread pool.
    def initialize(options = {})
      @connection        = options.fetch :connection, create_connection
      @exchange_name     = options.fetch :exchange_name, DEFAULT_EXCHANGE_NAME
      @publisher_threads = options.fetch :publisher_threads, 2
      @supervisor        = options.fetch :supervisor, create_supervisor
      @worker_classes    = options.fetch :worker_classes, []
      @worker_threads    = options.fetch :worker_threads, 3

      @managers = []

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

    # Internal: Returns the number of publisher threads in the publisher pool.
    attr_reader :publisher_threads

    # Internal: Returns the supervisor instance.
    attr_reader :supervisor

    # Internal: Returns an Array of Worker subclasses.
    attr_reader :worker_classes

    # Internal: Returns the number of worker threads per manager.
    attr_reader :worker_threads

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
      worker_classes.each do |worker_class|
        manager = create_manager(worker_class)
        @managers << manager
        supervisor.add_worker manager
      end

      nil
    end

    # Internal: Creates a new Bunny::Session and opens it.
    #
    # Returns an open Bunny::Session instance.
    def create_connection
      new_connection = Bunny.new
      new_connection.start

      new_connection
    end

    # Internal: Assign new Concurrent::Poolbox and Array[Publisher] to the
    #           manager's publishers_mailbox and publisher_pool properties
    #           respectively.
    #
    # Returns nil.
    def create_publisher_pool
      @publishers_mailbox, @publisher_pool = Publisher.pool(publisher_threads,
                                                            connection,
                                                            exchange_name)
    end

    # Internal: Creates a new Concurrent::Supervisor.
    #
    # Returns a Concurrent::Supervisor instance.
    def create_supervisor
      Concurrent::Supervisor.new
    end

    # Internal: Creates a Manager for a given Worker subclass adding relevant
    #           arguments from Runner properties.
    #
    # Returns a Manager instance.
    def create_manager(worker_class)
      Manager.new(connection, exchange_name, worker_class,
                  worker_threads: worker_threads)
    end
  end
end
