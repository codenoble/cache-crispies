lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'cache_crispies/version'

Gem::Specification.new do |spec|
  spec.name          = 'cache_crispies'
  spec.version       = CacheCrispies::VERSION
  spec.authors       = ['Adam Crownoble']
  spec.email         = 'adam@codenoble.com'
  spec.summary       = 'Fast Rails serializer with built-in caching'
  spec.homepage      = 'https://github.com/codenoble/cache-crispies'
  spec.licenses      = ['MIT']
  spec.metadata      = { 'source_code_uri' => 'https://github.com/codenoble/cache-crispies' }

  spec.files         = Dir.glob('{lib,spec}/**/*') + ['.rspec']
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1.0'

  spec.add_dependency 'railties', '>= 7.0.0', '< 9.0'
  spec.add_dependency 'oj', '~> 3.7'

  spec.add_development_dependency 'activemodel', '>= 7.0.0', '< 9.0'
  spec.add_development_dependency 'base64', '~> 0.2'
  spec.add_development_dependency 'mutex_m', '~> 0.3'
  spec.add_development_dependency 'appraisal', '~> 2.5'
  spec.add_development_dependency 'debug', '~> 1.10'
  spec.add_development_dependency 'rspec', '~> 3.13.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.6'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov-lcov', '~> 0.8'
end
