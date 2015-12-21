# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic_results/version'

Gem::Specification.new do |spec|
  spec.name          = 'elastic_results'
  spec.version       = ElasticResults::VERSION
  spec.authors       = ['Donavan Stanley']
  spec.email         = ['dstanley@covermymeds.com']

  spec.summary       = 'Formatters to shove test results into elastic search'
  spec.homepage      = 'https://github.com/covermymeds/elastic_results'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    fail 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry'
  spec.add_dependency 'elasticsearch'
  spec.add_dependency 'googl'
end
