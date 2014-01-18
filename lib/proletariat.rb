require 'proletariat/version'

require 'concurrent'
require 'bunny'
require 'logger'
require 'forwardable'

require 'proletariat/concurrency/actor'

require 'proletariat/manager'
require 'proletariat/publisher'
require 'proletariat/queue_config'
require 'proletariat/runner'
require 'proletariat/subscriber'
require 'proletariat/worker'

# Public: Creates the Proletariat namespace and holds a process-wide Runner
#         instance as well as a logger.
module Proletariat
  # Public: The default name used for the RabbitMQ topic exchange.
  DEFAULT_EXCHANGE_NAME = 'proletariat'

  class << self
    extend Forwardable

    # Public: Delegate lifecycle calls to the process-wide Runner.
    def_delegators :runner, :run, :run!, :stop, :running?, :publish, :purge

    # Public: Allows the setting of an alternate logger.
    #
    # logger - An object which fulfills the role of a Logger.
    attr_writer :logger

    # Public: Sets the process-wide Runner to an instance initialized with a
    #         given hash of options.
    #
    # options - A Hash of options (default: {}):
    #             :connection        - An open RabbitMQ::Session object.
    #             :exchange_name     - The RabbitMQ topic exchange name as a
    #                                  String.
    #             :logger            - An object which fulfills the role of a
    #                                  Logger.
    #             :publisher_threads - The size of the publisher thread pool.
    #             :supervisor        - A Supervisor instance.
    #             :worker_classes    - An Array of Worker subclasses.
    #             :worker_threads    - The size of the worker thread pool.
    def configure(options = {})
      self.logger = options.fetch(:logger, default_logger)

      @runner = Runner.new(defaults.merge(options))
    end

    # Internal: The logger used if no other is specified via .configure.
    #
    # Returns a Logger which logs to STDOUT.
    def default_logger
      Logger.new(STDOUT)
    end

    # Internal: Default process-wide Runner options.
    #
    # Returns a Hash of options.
    def defaults
      {
        worker_classes: workers_from_env || []
      }
    end

    def logger
      @logger ||= default_logger
    end

    def runner
      @runner ||= Runner.new(defaults)
    end

    def workers_from_env
      if ENV['WORKERS']
        ENV['WORKERS'].split(',').map(&:strip).map do |string|
          string
            .split('::')
            .reduce(Object) { |a, e| a.const_get(e) }
        end
      end
    end
  end
end
