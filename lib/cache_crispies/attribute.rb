module CacheCrispies
  class Attribute
    class InvalidCoersionType < ArgumentError; end

    def initialize(key, from: nil, with: nil, to: nil, nesting: [], conditions: [])
      @key = key
      @method_name = from || key || :itself
      @serializer = with
      @coerce_to = to
      @nesting = Array(nesting)
      @conditions = Array(conditions)
    end

    attr_reader :method_name, :key, :serializer, :coerce_to, :nesting, :conditions

    def value_for(model, options)
      value = model.public_send(method_name)

      serializer ? serialize(value, options) : coerce(value)
    end

    private

    def serialize(value, options)
      plan = CacheCrispies::Plan.new(serializer, value, options)

      if value.respond_to?(:each)
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
          InvalidCoersionType,
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