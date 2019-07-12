module CacheCrispies
  module Controller
    extend ActiveSupport::Concern

    OJ_MODE = :rails

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