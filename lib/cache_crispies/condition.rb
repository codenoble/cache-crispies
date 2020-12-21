# frozen_string_literal: true

module CacheCrispies
  # Represents an instance of a conditional built by a
  # {CacheCrispies::Base.show_if} call
  class Condition
    # Returns a new instance of Condition
    #
    # @param block [Proc] a block containing the logic for the condition
    def initialize(block)
      @block = block
    end

    # A system-wide unique ID used for memoizaiton
    #
    # @eturn [Integer] the unique ID for this condition
    def uid
      # Just reusing the block's object_id seems to make sense
      block.object_id
    end

    # Test the truthiness of the condition against the serializer instance
    #
    # @param serializer [Object] CacheCrispies::Base serializer instance
    # @return [Boolean] the condition's truthiness
    def true_for?(serializer)
      return !!serializer.public_send(block) if block.is_a?(Symbol)

      !!case block.arity
        when 0
          block.call
        when 1
          block.call(serializer.model)
        else
          block.call(serializer.model, serializer.options)
        end
    end

    private

    attr_reader :block
  end
end
