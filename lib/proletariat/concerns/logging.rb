module Proletariat
  module Concerns
    # Public: Mixin to handle logging concerns.
    module Logging
      # Public: Logs info to the process-wide logger.
      #
      # message - The message to be logged.
      #
      # Returns nil.
      def log_info(message)
        Proletariat.logger.info "#{self.class.name} #{object_id}: #{message}"

        nil
      end
    end
  end
end
