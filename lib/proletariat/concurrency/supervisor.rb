module Proletariat
  class Supervisor
    extend Forwardable

    def_delegators :true_supervisor, :run, :run!, :stop, :running?, :add_worker

    def [](mailbox_name)
      mailboxes[mailbox_name]
    end

    def add_supervisor(supervisor, opts = {})
      true_supervisor.add_worker supervisor, opts.merge(type: :supervisor)
    end

    def supervise_pool(mailbox_name, threads, actor_class, *arguments)
      mailboxes[mailbox_name], workers = Actor.pool(threads, actor_class,
                                                    *arguments)
      true_supervisor.add_workers workers
    end

    private

    def mailboxes
      @mailboxes ||= {}
    end

    def true_supervisor
      @true_supervisor ||= Concurrent::Supervisor.new
    end
  end
end
