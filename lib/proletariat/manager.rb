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
    def initialize(worker_class)
      super()

      @worker_class   = worker_class

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

    # Internal: Returns the Subscriber actor for this Manager.
    attr_reader :subscriber

    # Internal: Returns the subclass of Worker used to process messages.
    attr_reader :worker_class

    # Internal: Returns the pool of initialized workers.
    attr_reader :worker_pool

    # Internal: Returns a shared mailbox for the pool of workers.
    attr_reader :workers_mailbox

    # Internal: Assign a new Subscriber instance (configured for the current
    #           worker type) to the manager's subscriber property.
    #
    # Returns nil.
    def create_subscriber
      @subscriber = Subscriber.new(
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
      threads = Proletariat.worker_threads
      @workers_mailbox, @worker_pool = Actor.pool(threads, worker_class)

      nil
    end

    # Internal: Builds a new QueueConfig object passing in some settings from
    #           worker_class.
    #
    # Returns a new QueueConfig instance.
    def generate_queue_config
      QueueConfig.new(worker_class.name, worker_class.routing_keys, false)
    end
  end
end
