module Proletariat
  # Public: Global configuration object. Provides sensible defaults.
  class Configuration
    # Public: The default name used for the RabbitMQ topic exchange.
    DEFAULT_EXCHANGE_NAME = 'proletariat'

    # Public: The default number of threads to use for publishers.
    DEFAULT_PUBLISHER_THREADS = (ENV['PUBLISHER_THREADS'] || 2).to_i

    # Public: The default number of threads to use for each worker class.
    DEFAULT_WORKER_THREADS = (ENV['WORKER_THREADS'] || 3).to_i

    # Internal: Sets the RabbitMQ connection.
    attr_writer :connection

    # Internal: Sets the RabbitMQ topic exchange name.
    attr_writer :exchange_name

    # Internal: Sets the logger.
    attr_writer :logger

    # Internal: Sets the number of threads to use for publishers.
    attr_writer :publisher_threads

    # Internal: Sets the Array of Worker classes to use for background
    #           processing.
    attr_writer :worker_classes

    # Internal: Sets the number of threads to use for each Worker class.
    attr_writer :worker_threads

    # Public: Allows setting of the config attributes via a block.
    #
    # block - Block which modifies attributes by accessing them via #config.
    #
    # Returns nil.
    def configure_with_block(&block)
      ConfigurationDSL.new(self, &block).set_config

      nil
    end

    # Public: Returns the set connection or defaults to a new, open
    #         Bunny::Session
    #
    # Returns a Bunny::Session.
    def connection
      @connection ||= begin
        new_connection = Bunny.new
        new_connection.start

        new_connection
      end
    end

    # Public: Returns the set name of the exchange or a default.
    #
    # Returns a String.
    def exchange_name
      @exchange_name ||= DEFAULT_EXCHANGE_NAME
    end

    # Public: Returns the set logger or a default standard output logger.
    #
    # Returns a logger.
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    # Public: Returns the set number of publisher threads or a default.
    #
    # Returns a Fixnum.
    def publisher_threads
      @publisher_threads ||= DEFAULT_PUBLISHER_THREADS
    end

    # Public: Returns the set worker classes or a default pulled from the
    #         WORKERS env variable.
    #
    # Returns an array of Worker classes.
    def worker_classes
      @worker_classes ||= begin
        if ENV['WORKERS']
          WorkerDescriptionParser.parse ENV['WORKERS']
        else
          []
        end
      end
    end

    # Public: Returns the set number of worker threads or a default.
    #
    # Returns a Fixnum.
    def worker_threads
      @worker_threads ||= DEFAULT_WORKER_THREADS
    end

    private

    # Internal: Handles running a configuration block in a context to allow
    #           access to the configuration object via a call to #config.
    class ConfigurationDSL
      # Public: Creates a new ConfigurationDSL instance.
      #
      # configuration - The Configuration instance you intend to update.
      # block         - The block containing the config settings.
      def initialize(configuration, &block)
        @config = configuration
        @block = block
      end

      # Public: Runs the configuration block, exposing the configuration
      #         instance via the #config method.
      #
      # Returns nil.
      def set_config
        instance_eval(&block)

        nil
      end

      private

      # Internal: Returns the config block.
      attr_reader :block

      # Internal: Returns the Configuration instance.
      attr_reader :config
    end
  end
end
