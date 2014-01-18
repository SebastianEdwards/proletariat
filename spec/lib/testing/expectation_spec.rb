require 'proletariat/testing/expectation'

module Proletariat
  module Testing
    describe Expectation do
      describe '#on_topic' do
        it 'should return a new expectation with given topic' do
          expectation = Expectation.new([], 2)
          expect(expectation.on_topic('lolcats', 'dogs').topics).to \
            eq ['lolcats', 'dogs']
        end
      end
    end
  end
end
