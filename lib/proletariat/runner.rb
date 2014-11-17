module Proletariat
  # Public: Sets up a supervisor which maintains a single Publisher and a
  # per-worker Manager instance.
  class Runner
    extend Forwardable

    # Public: Start the workers.
    #
    # Returns nil.
    def run
      @managers = Proletariat.worker_classes.map do |worker_class|
        Manager.spawn!(name: "manager_#{worker_class.to_s}_#{object_id}",
                       supervise: true,
                       args: [worker_class])
      end

      managers.each { |manager| manager << :run }

      nil
    end

    # Public: Check whether the workers are currently running.
    def running?
      !!managers
    end

    # Public: Stop the workers.
    #
    # Returns nil.
    def stop
      managers.each { |manager| manager << :terminate! } if managers
      @managers = nil

      nil
    end

    private

    # Internal: Returns an Array of the currently supervised Managers.
    attr_reader :managers
  end
end
