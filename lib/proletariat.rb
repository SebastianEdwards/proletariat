require 'proletariat/version'

require 'concurrent'
require 'bunny'
require 'logger'
require 'forwardable'

require 'proletariat/concurrency/actor'
require 'proletariat/concurrency/supervisor'

require 'proletariat/util/worker_description_parser'

require 'proletariat/configuration'
require 'proletariat/manager'
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
    def_delegators :runner, :run, :run!, :stop, :running?, :publish, :purge

    # Public: Allows configuration of Proletariat via given block.
    #
    # block - Block containing configuration calls.
    #
    # Returns nil.
    def configure(&block)
      config.configure_with_block(&block)

      nil
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
  end
end
