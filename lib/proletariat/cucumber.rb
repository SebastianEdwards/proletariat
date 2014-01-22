require 'proletariat/testing'

# Mix testing helpers into World.
World(Proletariat::Testing)

# Hide logs by default.
AfterConfiguration do |_|
  Proletariat.configure do
    config.logger = Logger.new('/dev/null')
  end
end

# Ensure Proletariat running before each test.
Before do
  Proletariat.run! unless Proletariat.running?
end

# Stop workers and purge queues between scenarios.
After do
  Proletariat.stop
  Proletariat.purge
end
