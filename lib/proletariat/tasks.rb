require 'proletariat'

task :environment

namespace :proletariat do
  desc 'Start background processing'
  task :run => :environment do
    Proletariat.run
  end
end
