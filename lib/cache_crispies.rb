# frozen_string_literal: true

require 'active_support/dependencies'
require 'oj'

# The top level namespace module for the gem
module CacheCrispies
  # A prefix used in building cache key. This should be extra insurance against
  # key conflicts and also provides an easy way to search for keys in Redis.
  CACHE_KEY_PREFIX = 'cache-crispies'

  # The string to use to join parts of the cache keys together
  CACHE_KEY_SEPARATOR = '+'

  # Magic value for undefined arguments
  UNDEFINED = Object.new.freeze

  require 'cache_crispies/version'

  # Use autoload for better Rails development
  autoload :Attribute,      'cache_crispies/attribute'
  autoload :Base,           'cache_crispies/base'
  autoload :Collection,     'cache_crispies/collection'
  autoload :Condition,      'cache_crispies/condition'
  autoload :Optional,       'cache_crispies/optional'
  autoload :Configuration,  'cache_crispies/configuration'
  autoload :HashBuilder,    'cache_crispies/hash_builder'
  autoload :Memoizer,       'cache_crispies/memoizer'
  autoload :Controller,     'cache_crispies/controller'
  autoload :Plan,           'cache_crispies/plan'

  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.cache
    config.cache_store
  end
end
