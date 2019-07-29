# frozen_string_literal: true

require 'digest'
require 'rails'

module CacheCrispies
  # The Base class that all serializer classes should inherit from
  class Base
    attr_reader :model, :options

    # Define class-level instance variables and their default values when the
    # class is inherited by another class. This is not meant to be called
    # directly. It is called internally by Ruby.
    #
    # @param other [Class] the inheriting child class
    # @return [void]
    def self.inherited(other)
      other.instance_variable_set(:@attributes, [])
      other.instance_variable_set(:@nesting, [])
      other.instance_variable_set(:@conditions, [])
    end

    class << self
      attr_reader :attributes
    end
    delegate :attributes, to: :class

    # Initializes a new instance of CacheCrispies::Base, or really, it should
    # always be a subclass of CacheCrispies::Base.
    #
    # @param model [Object] typically ActiveRecord::Base, but could be anything
    # @param options [Hash] any optional custom values you want to be
    #   accessible in your subclass.
    def initialize(model, options = {})
      @model = model
      @options = options
    end

    # Renders the serializer instance to a JSON-ready Hash
    #
    # @return [Hash] a JSON-ready hash
    def as_json
      HashBuilder.new(self).call
    end

    # Whether or not this serializer class should allow caching of results.
    # It is set to false by default, but can be overridden in child classes.
    #
    # @return [Boolean]
    def self.do_caching?
      false
    end

    # A JSON key to use as a root key on a non-collection serializable. by
    # default it's the name of the class without the "Serializer" part. But it
    # can be overridden in a subclass to be anything.
    #
    # @return [Symbol] a symbol to be used as a key for a JSON-ready Hash
    def self.key
      to_s.demodulize.chomp('Serializer').underscore.to_sym
    end

    # A JSON key to use as a root key on a collection-type serializable. By
    # deafult it's the plural version of .key, but it can be overridden in a
    # subclass to be anything.
    #
    # @return [Symbol] a symbol to be used as a key for a JSON-ready Hash
    def self.collection_key
      return nil unless key

      key.to_s.pluralize.to_sym
    end

    # An array of strings that should be added to the cache key for an instance
    # of this serializer. Typically you'd add in the #cache_key or string value
    # for any extra models or data passed in through the options hash here. But
    # it could also contain any custom logic about how to construct a cache
    # key. This method is meant to be overridden in subclasses.
    #
    # @example cache based off models provided in options
    #   def self.cache_key_addons(options)
    #     [options[:current_user].cache_key]
    #   end
    #
    # @example time-based caching
    #   def self.cache_key_addons(_options)
    #     [Date.today.to_s]
    #   end
    #
    # @param options [Hash] the options hash passed to the serializer, will be
    # passed in here as well so you can refernce it if needed.
    # @return [Array<String>]
    def self.cache_key_addons(_options = {})
      []
    end

    # Return a cache key string for the serializer class to be included in the
    # cache key for the instances. The key includes the name of the class, and
    # a digest of the contents of the main class file.
    #
    # @return [String] a cache key for the class
    def self.cache_key_base
      @cache_key_base ||= "#{self}-#{file_hashes.join(CACHE_KEY_SEPARATOR)}"
    end

    # Return an array of cache key string for this serializer and all nested
    # and deeply nested serializers. The purpose of grabbing all this data is
    # to be able to construct a cache key that will be busted if any of the
    # nested serializers, no matter how deep, change at all.
    #
    # @return [Array<String>] an array of uniq, sorted serializer file hashes
    def self.file_hashes
      @file_hashes ||= (
        [file_hash] + nested_serializers.flat_map(&:file_hashes)
      ).uniq.sort
    end

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
      @nesting << key

      block.call

      @nesting.pop
    end
    private_class_method :nest_in

    def self.show_if(condition_proc, &block)
      @conditions << Condition.new(condition_proc)

      block.call

      @conditions.pop
    end
    private_class_method :show_if

    def self.nested_serializers
      attributes.map(&:serializer).compact
    end
    private_class_method :nested_serializers

    def self.serialize(*attribute_names, from: nil, with: nil, to: nil)
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
