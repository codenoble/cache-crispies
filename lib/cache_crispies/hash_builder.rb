# frozen_string_literal: true

module CacheCrispies
  # Builds out a JSON-ready Hash using the attributes in a Serializer
  class HashBuilder
    # Initializes a new instance of CacheCrispies::HashBuilder
    #
    # @param serializer [CacheCrispies::Base] an instance of a subclass of
    #   CacheCrispies::Base
    def initialize(serializer)
      @serializer = serializer
      @condition_results = Memoizer.new
    end

    # Builds the Hash
    #
    # @return [Hash]
    def call
      hash = {}

      serializer.attributes.each do |attrib|
        next unless show?(attrib)

        deepest_hash = hash

        attrib.nesting.each do |key|
          deepest_hash[key] ||= {}
          deepest_hash = deepest_hash[key]
        end

        value = value_for(attrib)

        if attrib.key
          deepest_hash[attrib.key] = value
        else
          deepest_hash.merge! value
        end
      end

      hash
    end

    private

    attr_reader :serializer, :condition_results

    def show?(attribute)
      # Memoize conditions so they aren't executed for each attribute in a
      # show_if block
      attribute.conditions.all? do |cond|
        condition_results.fetch(cond.uid) do
          cond.true_for?(serializer.model, serializer.options)
        end
      end
    end

    def value_for(attribute)
      meth = attribute.method_name

      target =
        if meth != :itself && serializer.respond_to?(meth)
          serializer
        else
          serializer.model
        end

      # TODO: rescue NoMethodErrors here with something more telling
      attribute.value_for(target, serializer.options)
    end
  end
end
