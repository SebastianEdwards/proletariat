require 'proletariat/util/worker_description_parser'

FakeWorker = Class.new
AnotherFakeWorker = Class.new

module Proletariat
  describe WorkerDescriptionParser do
    describe '.parse' do
      let(:logger) { double.as_null_object }

      before do
        stub_const 'Proletariat', double(logger: logger)
      end

      context 'worker classes exist' do
        it 'should return the worker classes' do
          parsed = WorkerDescriptionParser.parse 'FakeWorker,AnotherFakeWorker'
          expect(parsed).to eq [FakeWorker, AnotherFakeWorker]
        end
      end

      context 'worker classes do not exist' do
        it 'should return an empty array' do
          parsed = WorkerDescriptionParser.parse('NonexistantWorker')
          expect(parsed).to eq []
        end

        it 'should log a warning for the missing class' do
          expect(logger).to receive(:warn).with(/Missing worker class/)
          WorkerDescriptionParser.parse('NonexistantWorker')
        end
      end

      context 'some worker classes exist' do
        it 'should return only the existing classes' do
          parsed = WorkerDescriptionParser.parse 'FakeWorker,NonexistantWorker'
          expect(parsed).to eq [FakeWorker]
        end
      end
    end
  end
end
