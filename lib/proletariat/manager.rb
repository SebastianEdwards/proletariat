module Proletariat
  # Public: Maintains a pool of worker threads and a RabbitMQ subscriber
  #         thread. Uses information from the worker class to generate queue
  #         config.
  class Manager < Concurrent::Actor::RestartingContext
    # Public: Creates a new Manager instance.
    #
    # worker_class  - A subclass of Proletariat::Worker to handle messages.
    def initialize(worker_class)
      @workers = worker_class.pool(Proletariat.worker_threads, object_id)

      @subscriber = Subscriber.spawn!(
        name: "#{worker_class.to_s}_subscriber_#{object_id}",
        supervise: true,
        args: [
          workers,
          generate_queue_config(worker_class),
          get_exception_handler_class(worker_class)
        ]
      )
    end

    private

    # Internal: Returns the Subscriber actor for this Manager.
    attr_reader :subscriber

    # Internal: Returns an Array of Worker actors.
    attr_reader :workers

    def get_exception_handler_class(worker_class)
      if worker_class.exception_handler.is_a?(ExceptionHandler)
        worker_class.exception_handler
      else
        name = worker_class.exception_handler
                           .to_s
                           .split('_')
                           .map(&:capitalize)
                           .join

        Proletariat.const_get(name)
      end
    end

    # Internal: Builds a new QueueConfig from a given Worker subclass.
    #
    # worker_class - The Worker subclass to base settings on.
    #
    # Returns a new QueueConfig instance.
    def generate_queue_config(worker_class)
      QueueConfig.new(worker_class.name, worker_class.routing_keys,
                      Proletariat.test_mode?)
    end
  end
end
