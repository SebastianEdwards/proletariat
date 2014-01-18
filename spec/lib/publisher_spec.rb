require 'proletariat/publisher'

module Proletariat
  describe Publisher do
    let(:logger) { double }
    let(:connection) { double.as_null_object }
    let(:exchange_name) { 'great-exchange' }

    before do
      allow(Proletariat).to receive(:logger).and_return(logger)
    end

    describe '#started' do
      it 'should log status' do
        expect(logger).to receive(:info).with /online/
        Publisher.new(connection, exchange_name).started
      end
    end

    describe '#stopped' do
      it 'should log status' do
        expect(logger).to receive(:info).with /offline/
        Publisher.new(connection, exchange_name).stopped
      end
    end

    describe '#stopping' do
      it 'should log status' do
        expect(logger).to receive(:info).with /graceful shutdown/
        Publisher.new(connection, exchange_name).stopping
      end
    end
  end
end
