# frozen_string_literal: true

require 'rails'

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
