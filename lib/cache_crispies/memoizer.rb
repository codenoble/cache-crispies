# frozen_string_literal: true

module CacheCrispies
  # Simple class to handle memoizing values by a key. This really just provides
  # a bit of wrapper around doing this yourself with a hash.
  class Memoizer
    def initialize
      @cache = {}
    end

    # Fetches a cached value for the given key, if it exists. Otherwise it calls
    # the block and caches that value
    #
    # @param key [Object] the value to use as a cache key
    # @yield the value to cache and return if there is a cache miss
    # @return [Object] either the cached value or the block's value
    def fetch(key, &_block)
      # Avoid ||= because we need to memoize falsey values.
      return cache[key] if cache.key?(key)

      cache[key] = yield
    end

    private

    attr_reader :cache
  end
end
