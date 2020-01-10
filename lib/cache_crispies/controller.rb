# frozen_string_literal: true

module CacheCrispies
  # A Rails concern designed to be used in Rails controllers to provide access to
  # the #cache_render method
  module Controller
    extend ActiveSupport::Concern

    # The serialization mode that should be used with the oj gem
    OJ_MODE = :rails

    # Renders the provided cacheable object to JSON using the provided
    # serializer
    #
    # @param serializer [CacheCrispies::Base] a class inheriting from
    #   CacheCrispies::Base
    # @param cacheable [Object] can be any object. But is typically a Rails
    #   model inheriting from ActiveRecord::Base
    # @param key [Symbol] the name of the root key to nest the JSON
    #   data under
    # @param collection [Boolean] whether to render the data as a
    #   collection/array or a single object
    # @param status [Integer, Symbol] the HTTP response status code or
    #    Rails-supported symbol. See
    #    https://guides.rubyonrails.org/layouts_and_rendering.html#the-status-option
    # @param meta [Hash] data to include as metadata under a root key
    # @param meta_key [Symbol] they key to store the metadata under
    # @param [Hash] options any optional values from the serializer instance
    # @return [void]
    def cache_render(
      serializer,
      cacheable,
      key: nil, collection: nil, status: nil,
      meta: {}, meta_key: :meta,
      **options
    )
      plan = CacheCrispies::Plan.new(
        serializer,
        cacheable,
        key: key, collection: collection,
        **options
      )

      if CacheCrispies.config.etags?
        response.weak_etag = plan.etag
      end

      serializer_json =
        if plan.collection?
          plan.cache do
            CacheCrispies::Collection.new(
              cacheable, serializer, options
            ).as_json
          end
        else
          plan.cache { serializer.new(cacheable, options).as_json }
        end

      json_hash = plan.wrap(serializer_json)
      json_hash[meta_key] = meta unless meta.empty?

      render_hash = { json: Oj.dump(json_hash, mode: OJ_MODE) }
      render_hash[:status] = status if status

      render render_hash
    end
  end
end
