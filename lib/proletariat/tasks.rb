require 'proletariat'

task :environment

namespace :proletariat do
  desc 'Start background processing'
  task run: :environment do
    STDOUT.sync = true

    Proletariat.run!

    at_exit { Proletariat.stop }

    sleep
  end
end
