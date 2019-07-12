require 'active_support/dependencies'
require 'oj'

module CacheCrispies
  CACHE_KEY_PREFIX = 'cache-crispies'.freeze
  CACHE_KEY_SEPARATOR = '+'.freeze

  require 'cache_crispies/version'

  autoload :Attribute,    'cache_crispies/attribute'
  autoload :Base,         'cache_crispies/base'
  autoload :Collection,   'cache_crispies/collection'
  autoload :Condition,    'cache_crispies/condition'
  autoload :HashBuilder,  'cache_crispies/hash_builder'
  autoload :Memoizer,     'cache_crispies/memoizer'
  autoload :Controller,   'cache_crispies/controller'
  autoload :Plan,         'cache_crispies/plan'
end