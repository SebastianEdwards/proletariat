module Proletariat
  # Internal: Helper utility to parse and constantize strings into arrays of
  #           Worker classes.
  module WorkerDescriptionParser
    # Public: Parse given string into array of Worker classes.
    #
    # description - String to be parsed. Should contain comma-separated class
    #               names.
    #
    # Examples
    #
    #   WorkerDescriptionParser.parse('FirstWorker,SecondWorker')
    #   # => [FirstWorker, SecondWorker]
    #
    # Returns an Array of Worker classes.
    def self.parse(description)
      description.split(',').map(&:strip).map do |string|
        constantize string
      end.compact
    end

    private

    # Intenal: Performs constantizing of worker names into Classes.
    #
    # name - The name to be constantized.
    #
    # Returns the Worker class if valid.
    # Returns the nil if Worker class cannot be found.
    def self.constantize(name)
      name.split('::').reduce(Object) { |a, e| a.const_get(e) }
    rescue NameError => e
      Proletariat.logger.warn "Missing worker class: #{e.name}"
      nil
    end
  end
end
