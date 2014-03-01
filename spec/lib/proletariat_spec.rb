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
    attr_accessor :fail_mode
    attr_accessor :ponged
  end

  def work(message, routing_key, headers)
    if self.class.fail_mode == true
      fail 'Error' unless headers['failures'] == 2
    end

    self.class.ponged = true

    log 'PONG'
    sleep 0.5
    publish 'ping'

    :ok
  end
end

describe Proletariat do
  before do
    Proletariat.configure do
      config.logger         = Logger.new('/dev/null')
      config.worker_classes = [PingWorker, PongWorker]
    end

    PongWorker.fail_mode = false

    Proletariat.purge
    Proletariat.run!
    sleep 2
  end

  after do
    Proletariat.stop
    Proletariat.purge
    PingWorker.pinged = false
    PongWorker.ponged = false
  end

  it 'should roughly work' do
    Proletariat.publish 'ping', ''
    sleep 5

    expect(PingWorker.pinged).to be_truthy
    expect(PongWorker.ponged).to be_truthy
  end

  it 'should work in error conditions' do
    PongWorker.fail_mode = true
    Proletariat.publish 'ping', ''
    sleep 10

    expect(PingWorker.pinged).to be_truthy
    expect(PongWorker.ponged).to be_truthy
  end
end
