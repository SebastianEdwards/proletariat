require 'proletariat/queue_config'

module Proletariat
  describe QueueConfig do
    describe '#queue_name' do
      it 'should return an underscored version of the worker name' do
        queue_config = QueueConfig.new('ExampleWorker', ['lolcats'], false)
        expect(queue_config.queue_name).to eq 'example_worker'
      end
    end
  end
end
