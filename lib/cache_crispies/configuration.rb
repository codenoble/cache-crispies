# frozen_string_literal: true

require 'active_support'

module CacheCrispies
  class Configuration
    SETTINGS = [
      :cache_store,
      :etags
    ].freeze

    SETTINGS.each do |setting|
      attr_accessor setting
    end

    def initialize
      reset!
    end

    alias etags? etags

    # Resets all values to their defaults. Useful for testing.
    def reset!
      @cache_store = Rails.cache || ActiveSupport::Cache::NullStore.new
      @etags = false
    end
  end
end
