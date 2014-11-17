require 'proletariat/concurrency/actor_common'

module Proletariat
  # Public: Interface abstraction for Concurrent::Actor.
  class Actor < Concurrent::Actor::RestartingContext
    include ActorCommon

    def on_message(message)
      if respond_to?(:work_method)
        send work_method, message
      else
        work message
      end
    end
  end
end
