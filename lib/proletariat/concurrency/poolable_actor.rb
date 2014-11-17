require 'proletariat/concurrency/actor_common'

module Proletariat
  # Public: Interface abstraction for a pool of Concurrent::Actor instances.
  class PoolableActor < Concurrent::Actor::Utils::AbstractWorker
    include ActorCommon

    def on_message(message)
      if respond_to?(:work_method)
        send work_method, message
      else
        work message
      end
    ensure
      @balancer << :subscribe
    end

    def self.pool(pool_size, suffix = '')
      Concurrent::Actor::Utils::
        Pool.spawn!("#{to_s}_pool", pool_size) do |b, i|
          spawn(name: "#{to_s}_#{i}_#{suffix}", supervise: true, args: [b])
        end
    end
  end
end
