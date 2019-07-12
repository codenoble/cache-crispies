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

  spec.files         = Dir.glob('{lib,spec}/**/*') + ['.rspec']
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']

  # TODO: see if we can just require some action_* gems instead
  spec.add_dependency 'oj', '~> 3.7'
  spec.add_dependency 'rails', '~> 5.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'byebug', '~> 11.0'
  spec.add_development_dependency 'rspec', '~> 3.8.0'
end
