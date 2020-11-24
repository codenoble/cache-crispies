# frozen_string_literal: true

require 'active_support'

module CacheCrispies
  class Configuration
    SETTINGS = [
      :cache_store,
      :etags,
      :cache_key_method
    ].freeze

    SETTINGS.each do |setting|
      attr_accessor setting
    end

    def initialize
      reset!
    end

    alias etags? etags
    alias cache_key_method? cache_key_method

    # Resets all values to their defaults. Useful for testing.
    def reset!
      @cache_store = Rails.cache || ActiveSupport::Cache::NullStore.new
      @etags = false
      @cache_key_method = :cache_key
    end
  end
end
