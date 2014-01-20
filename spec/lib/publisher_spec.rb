require 'proletariat/publisher'

module Proletariat
  describe Publisher do
    let(:connection) { double.as_null_object }
    let(:exchange_name) { 'great-exchange' }
    let(:logger) { double }

    before do
      allow(Proletariat).to receive(:connection).and_return(connection)
      allow(Proletariat).to receive(:exchange_name).and_return(exchange_name)
      allow(Proletariat).to receive(:logger).and_return(logger)
    end

    describe '#started' do
      it 'should log status' do
        expect(logger).to receive(:info).with /online/
        Publisher.new.started
      end
    end

    describe '#stopped' do
      it 'should log status' do
        expect(logger).to receive(:info).with /offline/
        Publisher.new.stopped
      end
    end

    describe '#stopping' do
      it 'should log status' do
        expect(logger).to receive(:info).with /graceful shutdown/
        Publisher.new.stopping
      end
    end
  end
end
