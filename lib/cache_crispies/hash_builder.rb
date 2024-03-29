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
      return if @serializer.model.nil?

      hash = {}

      serializer.attributes.each do |attrib|
        deepest_hash = hash

        next unless show?(attrib)

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

    protected

    attr_reader :serializer, :condition_results

    def show?(attribute)
      # Memoize conditions so they aren't executed for each attribute in a
      # show_if block
      attribute.conditions.all? do |cond|
        condition_results.fetch(cond.uid) do
          cond.true_for?(serializer)
        end
      end
    end

    def target_for(attribute)
      meth = attribute.method_name

      if serializer.respond_to?(meth) && meth != :itself
        serializer
      else
        serializer.model
      end
    end

    def value_for(attribute)
      # TODO: rescue NoMethodErrors here with something more telling
      attribute.value_for(target_for(attribute), serializer.options)
    end
  end
end
