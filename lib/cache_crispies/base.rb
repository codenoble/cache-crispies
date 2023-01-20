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
    delegate :attributes, :attributes_by_nesting, to: :class

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

    # Renders the serializer instance to an Oj::StringWriter instance
    #
    # @return [Oj::StringWriter] an Oj::StringWriter instance with the
    #   serialized content
    def write_to_json(json_writer = nil)
      json_writer ||= Oj::StringWriter.new(mode: :rails)

      JsonBuilder.new(self).call(json_writer)

      json_writer
    end

    # Get or set whether or not this serializer class should allow caching of
    # results. It returns false by default, but can be overridden in child
    # classes. Calling the method with an argument will set the value, calling
    # it without any arguments will get the value.
    #
    # @param value [Boolean] true to enable caching, false to disable
    # @return [Boolean]
    def self.do_caching(value = nil)
      @do_caching ||= false

      # method called with no args so act as a getter
      return @do_caching if value.nil?

      # method called with args so act as a setter
      @do_caching = !!value
    end

    class << self
      alias do_caching? do_caching
    end

    # Get or set root path of Rails application or engine.
    # It uses Rails by default, but can be overriden with your Rails Engine class.
    # Calling the method with an argument will set the value, calling it without
    # any arguments will get the value.
    def self.engine(value = nil)
      @engine ||= superclass.try(:engine)
      @engine ||= Rails

      # method called with no args so act as a getter
      return @engine if value.nil?

      # method called with args so act as a setter
      @engine = value
    end

    # Get or set a JSON key to use as a root key on a non-collection
    # serializable. By default it's the name of the class without the
    # "Serializer" part. But it can be overridden in a subclass to be anything.
    # Calling the method with a key will set the key, calling it without any
    # arguments will get the key.
    #
    # @param key [Symbol, nil] a symbol to be used as a key for a JSON-ready
    # Hash, or nil for no key
    # @return [Symbol, nil] a symbol to be used as a key for a JSON-ready Hash,
    # or nil for no key
    def self.key(*key)
      @default_key ||= to_s.demodulize.chomp('Serializer').underscore.to_sym

      # method called with no args so act as a getter
      return defined?(@key) ? @key : @default_key if key.empty?

      # method called with args so act as a setter
      @key = key.first&.to_sym
    end

    # Get or set a JSON key to use as a root key on a collection-type
    # serializable. By deafult it's the plural version of .key, but it can be
    # overridden in a subclass to be anything. Calling the method with a key
    # will set the key, calling it without any arguments will get the key.
    #
    # @return [Symbol] a symbol to be used as a key for a JSON-ready Hash
    # @param key [Symbol, nil] a symbol to be used as a key for a JSON-ready
    # Hash, or nil for no key
    # @return [Symbol, nil] a symbol to be used as a key for a JSON-ready Hash,
    # or nil for no key
    def self.collection_key(*key)
      @default_collection_key ||= self.key.to_s.pluralize.to_sym

      # method called with no args so act as a getter
      if key.empty?
        if defined? @collection_key
          return @collection_key
        else
          return @default_collection_key
        end
      end

      # method called with args so act as a setter
      @collection_key = key.first&.to_sym
    end

    # Call with a block returning an array of strings that should be added to
    # the cache key for an instance of this serializer. Typically you'd add
    # in string values to uniquely represent the values you're passing to
    # the serializer so that they are cached separately. But it could also
    # contain any custom logic about how to construct a cache key.
    # Call without a block to act as a getter and return the value.
    #
    # @example cache based off models provided in options
    #   cache_key_addons { |options| [options[:current_user].id] }
    #
    # @example time-based caching
    #   cache_key_addons { |_options| [Date.today.to_s] }
    #
    # @param options [Hash] the options hash passed to the serializer, will be
    # passed in here as well so you can refernce it if needed.
    # @yield [options] a block that takes options passed to the serializer and
    # should return an array of strings to use in the cache key
    # @return [Array<String>]
    def self.cache_key_addons(options = {}, &block)
      @cache_key_addons ||= nil

      if block_given?
        @cache_key_addons = block
        nil
      else
        Array(@cache_key_addons&.call(options))
      end
    end

    # Get or set a cache key that can be changed whenever an outside dependency
    # of any kind changes in any way that could change the output of your
    # serializer. For instance, if a mixin is changed. Or maybe an object
    # you're serializing has changed it's #to_json method. This key should be
    # changed accordingly, to bust the cache so that you're not serving stale
    # data.
    #
    # @return [String] a version string in any form
    def self.dependency_key(key = nil)
      @dependency_key ||= nil

      # method called with no args so act as a getter
      return @dependency_key unless key

      # method called with args so act as a setter
      @dependency_key = key.to_s
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

    def self.attributes_by_nesting
      @attributes_by_nesting ||= (
        attributes.sort_by(&:nesting).group_by(&:nesting)
      )
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
        engine.root.join(*parts)
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

    def self.serialize(
      *attribute_names,
      from: nil, with: nil, through: nil, to: nil, collection: nil,
      optional: nil,
      &block
    )
      attribute_names.flat_map do |attrib|
        attrib = attrib&.to_sym
        current_nesting = Array(@nesting).dup
        current_conditions = Array(@conditions).dup

        @attributes <<
          Attribute.new(
            attrib,
            from: from,
            with: with,
            through: through,
            to: to,
            collection: collection,
            optional: optional,
            nesting: current_nesting,
            conditions: current_conditions,
            &block
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
