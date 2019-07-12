module CacheCrispies
  # Represents an instance of a conditional built by a show_if call
  class Condition
    def initialize(block)
      @block = block
    end

    # Public: A system-wide unique ID used for memoizaiton
    # Returns an Integer
    def uid
      # Just reusing the block's object_id seems to make sense
      block.object_id
    end

    def true_for?(model, options = {})
      !!case block.arity
        when 0
          block.call
        when 1
          block.call(model)
        else
          block.call(model, options)
        end
    end

    private

    attr_reader :block
  end
end