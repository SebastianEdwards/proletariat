require 'concurrent'
require 'proletariat/concurrency/actor_common'
require 'proletariat/concurrency/poolable_actor'
require 'proletariat/worker'

module Proletariat
  describe Worker do
    let(:balancer) { double.as_null_object }
    let(:logger)   { double.as_null_object }
    let(:worker)   { Worker.new(balancer) }

    before do
      allow(Proletariat).to receive(:logger).and_return(logger)
    end

    describe '#started' do
      it 'should log status' do
        expect(logger).to receive(:info).with /online/
        worker.started
      end
    end

    describe '#stopped' do
      it 'should log status' do
        expect(logger).to receive(:info).with /offline/
        worker.stopped
      end
    end

    describe '#work' do
      it 'should raise NotImplementedError' do
        expect { worker.work('message', 'key', {}) }.to \
          raise_exception NotImplementedError
      end
    end

    describe '#log' do
      context 'when message is provided' do
        it 'should log the message directly' do
          expect(logger).to receive(:info).with 'message to log'
          worker.log 'message to log'
        end
      end

      context 'when no message is provided' do
        it 'should return the logger instance' do
          expect(worker.log).to eq logger
        end
      end
    end

    describe '#publish' do
      it 'should forward the message to the publisher' do
        expect(Proletariat).to receive(:publish).with('topic', 'message', {})
        worker.publish 'topic', 'message', {}
      end

      it 'should have a blank default message' do
        expect(Proletariat).to receive(:publish).with('topic', '', {})
        worker.publish 'topic'
      end
    end

    describe '.listen_on' do
      it 'should add the given keys to routing_keys' do
        Worker.listen_on 'topic1', 'topic2'
        expect(Worker.routing_keys).to eq %w(topic1 topic2)
      end
    end

    describe '.routing_keys' do
      before do
        Worker.instance_variable_set :@routing_keys, nil
      end

      it 'should return an empty array by default' do
        expect(Worker.routing_keys).to eq []
      end
    end
  end
end
