require 'proletariat'

# Public: Test fixture
class PingWorker < Proletariat::Worker
  listen_on :ping

  class << self
    attr_accessor :pinged
  end

  def work(message, routing_key, headers)
    self.class.pinged = true

    log 'PING'
    sleep 0.5
    publish 'pong'

    :ok
  end
end

# Public: Test fixture
class PongWorker < Proletariat::Worker
  listen_on :pong

  class << self
    attr_accessor :ponged
  end

  def work(message, routing_key, headers)
    self.class.ponged = true

    log 'PONG'
    sleep 0.5
    publish 'ping'

    :ok
  end
end

describe Proletariat do
  it 'should roughly work' do
    Proletariat.configure do
      config.logger         = Logger.new('/dev/null')
      config.worker_classes = [PingWorker, PongWorker]
    end

    Proletariat.run!
    sleep 2
    Proletariat.publish 'ping', ''
    sleep 3
    Proletariat.stop
    Proletariat.purge

    expect(PingWorker.pinged).to be_truthy
    expect(PongWorker.ponged).to be_truthy
  end
end
