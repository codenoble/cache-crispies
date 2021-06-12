# frozen_string_literal: true

module CacheCrispies
  # Reperesents a single serialized attribute in a serializer. It's generated
  # by a call to either {CacheCrispies::Base.serialize} or
  # {CacheCrispies::Base.merge}.
  class Attribute
    # Represents an invalid option passed in the to: argument
    class InvalidCoercionType < ArgumentError; end

    # Initializes a new CacheCrispies::Attribute instance
    #
    # @param key [Symbol] the JSON key for this attribute
    # @param from [Symbol] the method on the model to call to get the value
    # @param with [CacheCrispies::Base] a serializer to use to serialize the
    # @param to [Class, Symbol] the data type to coerce the value into
    # @param collection [Boolean] force rendering as single or collection
    # @param optional [Boolean] render only if included in the option's
    #   `included` array
    # @param nesting [Array<Symbol>] the JSON keys this attribute will be
    #    nested inside
    # @param conditions [Array<CacheCrispies::Condition>] the show_if condition
    #   blocks this attribute is nested inside. These will be evaluated for
    #   thruthiness and must all be true for this attribute to reneder.
    #   argument's value
    def initialize(
      key,
      from: nil, with: nil, through: nil, to: nil, collection: nil,
      optional: nil,
      nesting: [], conditions: [],
      &block
    )
      @key = key
      @method_name = from || key || :itself
      @serializer = with
      @through = through
      @coerce_to = to
      @collection = collection
      @nesting = Array(nesting)
      @conditions = Array(conditions)
      @block = block

      @conditions << Optional.new(key) if optional
    end

    attr_reader(
      :method_name,
      :key,
      :serializer,
      :through,
      :coerce_to,
      :collection,
      :nesting,
      :conditions,
      :block
    )

    # Gets the value of the attribute for the given target object and options
    #
    # @param target [Object] typically ActiveRecord::Base, but could be anything
    # @param options [Hash] any optional values from the serializer instance
    # @return the value for the attribute for the given model and options
    # @raise [InvalidCoercionType] when an invalid argument is passed in the
    #   to: argument
    def value_for(target, options)
      value =
        if block?
          block.call(target, options)
        elsif through?
          target.public_send(through)&.public_send(method_name)
        else
          target.public_send(method_name)
        end

      serializer ? serialize(value, options) : coerce(value)
    end

    private

    def through?
      !through.nil?
    end

    def block?
      !block.nil?
    end

    # Here we'll render the attribute with a given serializer and attempt to
    # cache the results for better cache reusability
    def serialize(value, options)
      plan = CacheCrispies::Plan.new(
        serializer, value, collection: collection, **options
      )

      if plan.collection?
        plan.cache { Collection.new(value, serializer, options).as_json }
      else
        plan.cache { serializer.new(value, options).as_json }
      end
    end

    def coerce(value)
      return value if coerce_to.nil?

      case coerce_to.to_s.to_sym
      when :String
        value.to_s
      when :Integer
        try_coerce_via_string(value, :to_i)
      when :Float
        try_coerce_via_string(value, :to_f)
      when :BigDecimal
        BigDecimal(value)
      when :Array
        Array(value)
      when :Hash
        value.respond_to?(:to_h) ? value.to_h : value.to_hash
      when :bool, :boolean, :TrueClass, :FalseClass
        !!value
      else
        raise(
          InvalidCoercionType,
          "#{coerce_to} has no registered coercion strategy"
        )
      end
    end

    def try_coerce_via_string(value, method_name)
      (
        value.respond_to?(method_name) ? value : value.to_s
      ).public_send(method_name)
    end
  end
end
