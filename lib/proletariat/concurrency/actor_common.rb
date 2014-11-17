module Proletariat
  # Internal: Common behavior for actor base classes.
  module ActorCommon
    def self.included(base)
      base.class_exec do
        def initialize(*args)
          starting if respond_to?(:starting)

          super

          started if respond_to?(:started)
        end
      end
    end

    def on_event(event)
      if event == :terminated
        stopping if respond_to?(:stopping)

        cleanup if respond_to?(:cleanup)

        super

        stopped if respond_to?(:stopped)
      else
        super
      end
    end
  end
end
