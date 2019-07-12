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
    # @param options [Hash] any hash of custom options that should be passed
    #   to the serializer instance
    # @return [void]
    def cache_render(serializer, cacheable, options = {})
      plan = CacheCrispies::Plan.new(serializer, cacheable, options)

      # TODO: It would probably be good to add configuration to etiher
      # enable or disable this
      response.weak_etag = plan.etag

      serializer_json =
        if plan.collection?
          cacheable.map do |one_cacheable|
            plan.cache { serializer.new(one_cacheable, options).as_json }
          end
        else
          plan.cache { serializer.new(cacheable, options).as_json }
        end

      render json: Oj.dump(plan.wrap(serializer_json), mode: OJ_MODE)
    end
  end
end
