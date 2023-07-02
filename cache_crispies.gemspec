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
  spec.metadata          = { 'source_code_uri' => 'https://github.com/example/example' }

  spec.files         = Dir.glob('{lib,spec}/**/*') + ['.rspec']
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_dependency 'railties', '>= 6.0.0', '< 8.0'
  spec.add_dependency 'oj', '~> 3.7'

  spec.add_development_dependency 'activemodel', '>= 6.0.0', '< 8.0'
  spec.add_development_dependency 'appraisal', '~> 2.4'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'debug', '~> 1.8'
  spec.add_development_dependency 'rspec', '~> 3.12.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.4'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov-lcov', '~> 0.8'
end
