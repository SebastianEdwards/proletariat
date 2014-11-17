require 'proletariat/version'

require 'concurrent'
require 'bunny'
require 'logger'
require 'forwardable'

require 'proletariat/concurrency/actor'
require 'proletariat/concurrency/poolable_actor'

require 'proletariat/util/worker_description_parser'

require 'proletariat/configuration'
require 'proletariat/manager'
require 'proletariat/message'
require 'proletariat/publisher'
require 'proletariat/queue_config'
require 'proletariat/runner'
require 'proletariat/subscriber'
require 'proletariat/worker'

# Public: Creates the Proletariat namespace and holds a process-wide Runner
#         instance as well as access to the configuration attributes.
module Proletariat
  class << self
    extend Forwardable

    # Public: Delegate lifecycle calls to the process-wide Runner.
    def_delegators :runner, :run, :running?, :stop

    # Public: Allows configuration of Proletariat via given block.
    #
    # block - Block containing configuration calls.
    #
    # Returns nil.
    def configure(&block)
      config.configure_with_block(&block)

      nil
    end

    def publish(to, body = '', headers = {})
      publisher_pool << Message.new(to, body, headers)
    end

    def runner
      @runner ||= Runner.new
    end

    def method_missing(method_sym, *arguments, &block)
      if config.respond_to? method_sym
        config.send(method_sym, *arguments, &block)
      else
        super
      end
    end

    private

    # Internal: Global configuration object.
    def config
      @config ||= Configuration.new
    end

    def publisher_pool
      @publisher_pool ||= Publisher.pool(Proletariat.publisher_threads)
    end
  end
end
