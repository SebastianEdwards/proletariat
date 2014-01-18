require 'proletariat/testing/expectation_guarantor'

module Proletariat
  module Testing
    describe ExpectationGuarantor::MessageCounter do
      describe '#expected_messages_received?' do
        context 'count is equal or greater than expected' do
          it 'should return true' do
            counter = ExpectationGuarantor::MessageCounter.new(1, 3)
            expect(counter.expected_messages_received?).to be_truthy
          end
        end

        context 'count is less than expected' do
          it 'should return false' do
            counter = ExpectationGuarantor::MessageCounter.new(5, 3)
            expect(counter.expected_messages_received?).to be_falsey
          end
        end
      end

      describe '#post?' do
        class FakeBlockTaker
          attr_reader :block

          def initialize(&block)
            @block = block
          end
        end

        before do
          stub_const 'Concurrent::Future', FakeBlockTaker
        end

        it 'should increment the count' do
          counter = ExpectationGuarantor::MessageCounter.new(1)
          counter.post?('message')
          expect(counter.expected_messages_received?).to be_truthy
        end

        it 'should return a future containing :ok' do
          counter = ExpectationGuarantor::MessageCounter.new(1)
          expect(Concurrent::Future).to receive(:new)
          counter.post?('message')
        end

        it 'should ensure the returned future contains :ok' do
          counter = ExpectationGuarantor::MessageCounter.new(1)
          future = counter.post?('message')
          expect(future.block.call).to eq :ok
        end
      end
    end
  end
end
