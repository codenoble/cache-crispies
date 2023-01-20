# frozen_string_literal: true

module CacheCrispies
  # Builds out a JSON string directly with Oj::StringWriter
  class JsonBuilder < HashBuilder
    # Builds the JSON string with Oj::StringWriter
    #
    # @return [Oj::StringWriter]
    def call(json_writer, flat: false)
      if @serializer.model.nil?
        json_writer.push_value(nil)
        return
      end

      json_writer.push_object unless flat

      last_nesting = []

      serializer.attributes_by_nesting.each do |nesting, attributes|
        prefix_length = common_prefix_length(last_nesting, nesting)

        (last_nesting.length - prefix_length).times do
          json_writer.pop
        end

        nesting[prefix_length..-1].each do |key|
          json_writer.push_object(key.to_s)
        end

        attributes.each do |attrib|
          write_attribute(json_writer, attrib) if show?(attrib)
        end

        last_nesting = nesting
      end

      last_nesting.each do
        json_writer.pop
      end

      json_writer.pop unless flat

      json_writer
    end

    protected

    def write_attribute(json_writer, attribute)
      # TODO: rescue NoMethodErrors here with something more telling
      attribute.write_to_json(
        json_writer,
        target_for(attribute),
        serializer.options
      )
    end

    private

    def common_prefix_length(array1, array2)
      (0...[array1.length, array2.length].min).each do |i|
        return i if array1[i] != array2[i]
      end

      array1.length
    end
  end
end
