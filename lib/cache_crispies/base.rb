require 'digest'
require 'rails'

module CacheCrispies
  class Base
    attr_reader :model, :options

    def initialize(model, options = {})
      @model = model
      @options = options
    end

    def as_json
      HashBuilder.new(self).call
    end

    def self.do_caching?
      false
    end

    def self.key
      to_s.demodulize.chomp('Serializer').underscore.to_sym
    end

    def self.collection_key
      return nil unless key

      key.to_s.pluralize.to_sym
    end

    # Can be overridden in subclasses
    # options: Hash of the same options that would be passed to the
    #          individual serializer instances
    def self.cache_key_addons(_options = {})
      []
    end

    def self.cache_key_base
      # TODO: we may need to get a cache key from nested serializers as well :(
      @cache_key_base ||= "#{self}-#{file_hash}"
    end

    def self.attributes
      @attributes || []
    end
    delegate :attributes, to: :class

    private

    def self.file_hash
      @file_hash ||= Digest::MD5.file(path).to_s
    end
    private_class_method :file_hash

    def self.path
      @path ||= begin
        parts = %w[app serializers]
        parts += to_s.deconstantize.split('::').map(&:underscore)
        parts << "#{to_s.demodulize.underscore}.rb"
        Rails.root.join(*parts)
      end
    end
    private_class_method :path

    def self.nest_in(key, &block)
      @nesting ||= []
      @nesting << key

      block.call

      @nesting.pop
    end
    private_class_method :nest_in

    def self.show_if(condition_proc, &block)
      @conditions ||= []
      @conditions << Condition.new(condition_proc)

      block.call

      @conditions.pop
    end
    private_class_method :show_if

    def self.serialize(*attribute_names, from: nil, with: nil, to: nil)
      @attributes ||= []

      attribute_names.flatten.map { |att| att&.to_sym }.map do |attrib|
        current_nesting = Array(@nesting).dup
        current_conditions = Array(@conditions).dup

        @attributes <<
          Attribute.new(
            attrib,
            from: from,
            with: with,
            to: to,
            nesting: current_nesting,
            conditions: current_conditions
          )
      end
    end
    private_class_method :serialize

    def self.merge(attribute = nil, with: nil)
      serialize(nil, from: attribute, with: with)
    end
    private_class_method :merge
  end
end