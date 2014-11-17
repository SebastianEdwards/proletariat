# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'proletariat/version'

Gem::Specification.new do |s|
  s.name        = 'proletariat'
  s.version     = Proletariat::VERSION
  s.authors     = ['Sebastian Edwards']
  s.email       = ['me@sebastianedwards.co.nz']
  s.homepage    = 'https://github.com/SebastianEdwards/proletariat'
  s.summary     = %q{Lightweight background processing powered by RabbitMQ}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec', '3.1.0'
  s.add_development_dependency 'rubocop'

  s.add_runtime_dependency 'concurrent-ruby', '~> 0.7'
  s.add_runtime_dependency 'bunny', '~> 1.6.3'
end
