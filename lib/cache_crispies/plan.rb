module CacheCrispies
  class Plan
    attr_reader :serializer, :cacheable, :options

    def initialize(serializer, cacheable, options = {})
      @serializer = serializer
      @cacheable = cacheable
      @key = options.delete(:key)
      @options = options
    end

    def collection?
      cacheable.respond_to?(:each)
    end

    def etag
      Digest::MD5.hexdigest(cache_key)
    end

    def cache_key
      @cache_key ||=
        [
          CACHE_KEY_PREFIX,
          serializer.cache_key_base,
          addons_key,
          cacheable.cache_key
        ].flatten.compact.join(CACHE_KEY_SEPARATOR)
    end

    def cache
      if cache?
        Rails.cache.fetch(cache_key) { yield }
      else
        yield
      end
    end

    def wrap(json_hash)
      return json_hash unless key?

      { key => json_hash }
    end

    private

    def key
      return @key unless @key.nil?

      (collection? ? serializer.collection_key : serializer.key)
    end

    def key?
      !!key
    end

    def cache?
      serializer.do_caching? && cacheable.respond_to?(:cache_key)
    end

    def addons_key
      addons = serializer.cache_key_addons(options)

      return nil if addons.compact.empty?

      Digest::MD5.hexdigest(addons.join('|'))
    end
  end
end