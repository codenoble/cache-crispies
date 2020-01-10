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
    # @param [Hash] options any optional values from the serializer instance
    # @option options [Symbol] :key the name of the root key to nest the JSON
    #   data under
    # @option options [Boolean] :collection whether to render the data as a
    #   collection/array or a single object
    # @option options [Integer, Symbol] :status the HTTP response status code
    #    or Rails-supported symbol. See
    #    https://guides.rubyonrails.org/layouts_and_rendering.html#the-status-option
    # @return [void]
    def cache_render(serializer, cacheable, key: nil, collection: nil, status: nil, **options)
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

      render_hash = { json: Oj.dump(plan.wrap(serializer_json), mode: OJ_MODE) }
      render_hash[:status] = status if status

      render render_hash
    end
  end
end
