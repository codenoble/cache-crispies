module CacheCrispies
  class Memoizer
    def initialize
      @cache = {}
    end

    def fetch(key, &_block)
      # Avoid ||= because we need to memoize falsey values.
      return cache[key] if cache.key?(key)

      cache[key] = yield
    end

    private

    attr_reader :cache
  end
end