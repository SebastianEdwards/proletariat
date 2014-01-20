# Internal: Value object to hold RabbitMQ settings.
class QueueConfig < Struct.new(:worker_name, :routing_keys, :auto_delete)
  # Public: Create an underscored RabbitMQ queue name from the worker_name.
  #
  # Examples
  #
  #   config = QueueConfig.new('ExampleWorker', ...)
  #   config.queue_name
  #   # => 'example_worker'
  #
  # Returns the queue name as a String.
  def queue_name
    @queue_name ||= begin
      worker_name
        .gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
    end
  end
end
