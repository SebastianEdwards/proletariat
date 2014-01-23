module Proletariat
  # Public: Maintains a pool of worker threads and a RabbitMQ subscriber
  #         thread. Uses information from the worker class to generate queue
  #         config.
  class Manager
    # Public: Creates a new Manager instance.
    #
    # worker_class  - A subclass of Proletariat::Worker to handle messages.
    def initialize(worker_class)
      @supervisor = Supervisor.new

      supervisor.supervise_pool('workers', Proletariat.worker_threads,
                                worker_class)

      @subscriber = Subscriber.new(supervisor['workers'],
                                   generate_queue_config(worker_class))

      supervisor.add_worker subscriber
    end

    # Delegate lifecycle calls to supervisor. Cannot use Forwardable due to
    # concurrent-ruby API checking implementation.
    %w(run stop running?).each do |method|
      define_method(method) { supervisor.send method }
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

    # Internal: The supervisor used to manage the Workers and Subscriber
    attr_reader :supervisor

    # Internal: Builds a new QueueConfig from a given Worker subclass.
    #
    # worker_class - The Worker subclass to base settings on.
    #
    # Returns a new QueueConfig instance.
    def generate_queue_config(worker_class)
      QueueConfig.new(worker_class.name, worker_class.routing_keys, false)
    end
  end
end
