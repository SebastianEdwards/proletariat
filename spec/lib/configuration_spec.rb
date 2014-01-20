require 'proletariat'

FirstWorker = Class.new
SecondWorker = Class.new

module Proletariat
  describe Configuration do
    describe '#configure_with_block' do
      it 'should allow configuration via `config.[attribute]=`' do
        configuration = Configuration.new
        expect(configuration).to receive(:connection=).with('new connection')
        configuration.configure_with_block do
          config.connection = 'new connection'
        end
      end
    end

    describe '#connection' do
      let(:new_session) { double.as_null_object }

      before do
        stub_const 'Bunny', double(new: new_session)
      end

      it 'should default to a creating a new bunny session' do
        expect(Bunny).to receive(:new)
        Configuration.new.connection
      end

      it 'should open any new bunny sessions' do
        expect(new_session).to receive(:start)
        Configuration.new.connection
      end
    end

    describe '#exchange_name' do
      it 'should default to proletariat' do
        expect(Configuration.new.exchange_name).to eq 'proletariat'
      end
    end

    describe '#logger' do
      it 'should default to STDOUT' do
        expect(Logger).to receive(:new).with(STDOUT)
        Configuration.new.logger
      end
    end

    describe '#publisher_threads' do
      it 'should default to 2' do
        expect(Configuration.new.publisher_threads).to eq 2
      end
    end

    describe '#worker_classes' do
      context 'WORKERS env variable is set' do
        before do
          ENV['WORKERS'] = 'FirstWorker,SecondWorker'
        end

        after do
          ENV['WORKERS'] = nil
        end

        it 'should default to workers in env variable' do
          expect(Configuration.new.worker_classes).to \
            eq [FirstWorker, SecondWorker]
        end
      end

      context 'WORKERS env variable is not set' do
        it 'should default to an empty array' do
          expect(Configuration.new.worker_classes).to \
            eq []
        end
      end
    end

    describe '#worker_threads' do
      it 'should default to 3' do
        expect(Configuration.new.worker_threads).to eq 3
      end
    end
  end
end
