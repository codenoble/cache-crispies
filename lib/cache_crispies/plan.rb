# frozen_string_literal: true

module CacheCrispies
  # Represents a plan on how to cache a given cacheable with a given serializer
  class Plan
    attr_reader :serializer, :cacheable, :options

    # Initializes a new instance of CacheCrispies::Plan
    #
    # @param serializer [CacheCrispies::Base] a class inheriting from
    #   CacheCrispies::Base
    # @param cacheable [Object] typically ActiveRecord::Base or an enumerable
    #   containing instances of ActiveRecord::Base, but could be anything
    # @param [Hash] options any optional values from the serializer instance
    # @option options [Symbol] :key the name of the root key to nest the JSON
    #   data under
    # @option options [Boolean] :collection whether to render the data as a
    #   collection/array or a single object
    def initialize(serializer, cacheable, options = {})
      @serializer = serializer
      @cacheable = cacheable

      opts = options.dup
      @key = opts.delete(:key)
      @collection = opts.delete(:collection)
      @options = opts
    end

    # Whether or not the cacheable should be treated like a collection
    #
    # @return [Boolean] true if cacheable is a collection
    def collection?
      return @collection unless @collection.nil?

      @collection = cacheable.respond_to?(:each)
    end

    # Returns the cache_key in a format suitable for an ETag header
    #
    # @return [String] an MD5 digest of cache_key
    def etag
      Digest::MD5.hexdigest(cache_key)
    end

    # Returns a string of cache keys for all dependent objects. Changes to any
    # of keys should bust the overall key for this plan. The key consists of:
    # - a global key for this gem
    # - the serializers class name
    # - a digest of the contents of the of serializer class file
    # - any addon keys the serializer may define
    # - the #cache_key method on the cacheable (ActiveRecord provides this by
    #   default)
    #
    # @return [String] a suitable cache key
    def cache_key
      @cache_key ||=
        [
          CACHE_KEY_PREFIX,
          serializer.cache_key_base,
          serializer.dependency_key,
          addons_key,
          cacheable.cache_key
        ].flatten.compact.join(CACHE_KEY_SEPARATOR)
    end

    # Caches the contents of the block, if the plan is cacheable, otherwise
    # calls yields to the block directly
    #
    # @yield calls the block that should return a value to be cached
    # @return whatever the provided block returns
    def cache
      if cache?
        Rails.cache.fetch(cache_key) { yield }
      else
        yield
      end
    end

    # Wraps a value in a JSON key/object. Returns json_hash directly if there
    # is no key.
    #
    # @param json_hash [Hash, Array, Object] typically a JSON-ready Hash or
    #   Array, but could be anything really
    # @return [Hash, Object] will return a hash with a single key of #key,
    #   unless there is no #key, then returns the json_hash directly.
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
