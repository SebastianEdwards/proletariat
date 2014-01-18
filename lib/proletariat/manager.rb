module Proletariat
  # Public: Maintains a pool of worker threads and a RabbitMQ subscriber
  #         thread. Uses information from the worker class to generate queue
  #         config.
  class Manager < Concurrent::Supervisor
    # Public: Creates a new Manager instance.
    #
    # connection    - An open Bunny::Session object.
    # exchange_name - A String of the RabbitMQ topic exchange.
    # worker_class  - A subclass of Proletariat::Worker to handle messages.
    # options       - A Hash of additional optional parameters (default: {}):
    #                 :worker_threads - The size of the worker thread pool.
    def initialize(connection, exchange_name, worker_class, options = {})
      super()

      @connection     = connection
      @exchange_name  = exchange_name
      @worker_class   = worker_class
      @worker_threads = options.fetch :worker_threads, 3

      create_worker_pool
      create_subscriber

      worker_pool.each { |worker| add_worker worker }
      add_worker subscriber
    end

    # Public: Purge the RabbitMQ queue.
    #
    # Returns nil.
    def purge
      subscriber.purge

      nil
    end

    private

    # Internal: Returns an open Bunny::Session object.
    attr_reader :connection

    # Internal: Returns the name of the RabbitMQ topic exchange.
    attr_reader :exchange_name

    # Internal: Returns the Subscriber actor for this Manager.
    attr_reader :subscriber

    # Internal: Returns the subclass of Worker used to process messages.
    attr_reader :worker_class

    # Internal: Returns the pool of initialized workers.
    attr_reader :worker_pool

    # Internal: Returns a shared mailbox for the pool of workers.
    attr_reader :workers_mailbox

    # Internal: Returns the number of worker threads in the worker pool.
    attr_reader :worker_threads

    # Internal: Assign a new Subscriber instance (configured for the current
    #           worker type) to the manager's subscriber property.
    #
    # Returns nil.
    def create_subscriber
      @subscriber = Subscriber.new(
        connection,
        workers_mailbox,
        generate_queue_config
      )

      nil
    end

    # Internal: Assign new Concurrent::Poolbox and Array[Worker] to the
    #           manager's workers_mailbox and worker_pool properties
    #           respectively.
    #
    # Returns nil.
    def create_worker_pool
      @workers_mailbox, @worker_pool = Actor.pool(worker_threads, worker_class)

      nil
    end

    # Internal: Builds a new QueueConfig object passing in some settings from
    #           worker_class.
    #
    # Returns a new QueueConfig instance.
    def generate_queue_config
      QueueConfig.new(
        worker_class.name,
        exchange_name,
        worker_class.routing_keys,
        worker_threads,
        false
      )
    end
  end
end
