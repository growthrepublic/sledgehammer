$:.push File.expand_path("../lib", __FILE__)
require 'sledgehammer/version'

Gem::Specification.new do |spec|
  spec.name    = 'sledgehammer'
  spec.version = Sledgehammer::VERSION

  spec.authors     = ['Michał Matyas']
  spec.email       = ['michal@higher.lv']
  spec.summary     = 'Crawls websites and harvests e-mails'
  spec.description = 'Website crawler harvesting e-mails. Uses Sidekiq and Typhoeus.'
  spec.homepage    = 'https://github.com/d4rky-pl/sledgehammer'
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-sidekiq', '~> 1.1'

  spec.add_runtime_dependency 'activerecord', '~> 4.1'
  spec.add_runtime_dependency 'typhoeus', '~> 0.6'
  spec.add_runtime_dependency 'sidekiq', '~> 3.1'

end
