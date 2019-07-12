require 'rails'

module CacheCrispies
  class Collection
    def initialize(collection, serializer, options = {})
      @collection = collection
      @serializer = serializer
      @options = options
    end

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
      collection.map do |model|
        serializer.new(model, options).as_json
      end
    end

    def cached_json
      models_by_cache_key = collection.each_with_object({}) do |model, hash|
        plan = Plan.new(serializer, model, options)

        hash[plan.cache_key] = model
      end

      Rails.cache.fetch_multi(models_by_cache_key.keys) do |cache_key|
        model = models_by_cache_key[cache_key]

        serializer.new(model, options).as_json
      end
    end
  end
end