# frozen_string_literal: true

module CacheCrispies
  # Handles rendering and possibly caching a collection of models using a
  #   Serializer
  class Collection
    # Initializes a new instance of CacheCrispies::Collection
    #
    # @param colleciton [Object] typically an enumerable containing instances of
    #   ActiveRecord::Base, but could be any enumerable
    # @param serializer [CacheCrispies::Base] a class inheriting from
    #   CacheCrispies::Base
    # @param options [Hash] any optional values from the serializer instance
    def initialize(collection, serializer, options = {})
      @collection = collection
      @serializer = serializer
      @options = options
    end

    # Renders the collection to a JSON-ready Hash trying to cache the hash
    #   along the way
    #
    # @return [Hash] the JSON-ready Hash
    def as_json
      if serializer.do_caching? && collection.respond_to?(:cache_key)
        cached_json
      else
        uncached_json
      end
    end

    private

    attr_reader :collection, :serializer, :options

    def uncached_json
      @serializer.preloads(collection, options)
      collection.map do |model|
        serializer.new(model, options).as_json
      end
    end

    def cached_json
      models_by_cache_key = collection.each_with_object({}) do |model, hash|
        plan = Plan.new(serializer, model, **options)

        hash[plan.cache_key] = model
      end

      already_cached = CacheCrispies.cache.read_multi(*models_by_cache_key.keys)

      missing_keys = models_by_cache_key.keys - already_cached.keys
      missing_values = models_by_cache_key.fetch_values(*missing_keys)
      @serializer.preloads(missing_values, options)

      new_entries = missing_keys.each_with_object({}) do |key, hash|
        hash[key] = serializer.new(models_by_cache_key[key], options).as_json
      end

      CacheCrispies.cache.write_multi(new_entries)
      new_entries.values + already_cached.values
    end
  end
end
