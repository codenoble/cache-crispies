# frozen_string_literal: true

module CacheCrispies
  # Represents an optional condition
  class Optional
    # Returns a new instance of Optional
    #
    # @param block [Proc] the key of the attribute to include
    def initialize(key)
      @key = key
    end

    # A system-wide unique ID used for memoizaiton
    #
    # @eturn [Integer] the unique ID for this condition
    def uid
      # Just reusing the key seems to make sense
      key
    end

    # Test the truthiness of the optional condition against a model and options
    #
    # @param model [Object] typically ActiveRecord::Base, but could be anything
    # @param options [Hash] any optional values from the serializer instance
    # @return [Boolean] the condition's truthiness
    def true_for?(serializer)
      included = Array(serializer.options.fetch(:include, [])).map(&:to_sym)

      included.include?(key) || included.include?(:*)
    end

    private

    attr_reader :key
  end
end
