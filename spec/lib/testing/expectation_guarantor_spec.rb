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
    end
  end
end
