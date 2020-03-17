module Pb
  module Serializable
    def self.included(base)
      base.extend ClassMethods
      base.include ComputedModel
    end

    def to_pb(with: nil)
      if with.nil?
        with = ::Pb::Serializer.build_default_mask(self.class.message_class.descriptor)
      end

      self.class.bulk_load_and_compute(Array(self), with)

      oneof_set = []

      o = self.class.message_class.new
      self.class.message_class.descriptor.each do |fd|
        attr = self.class.find_attribute_by_field_descriptor(fd)

        next unless attr # TODO

        raise "#{self.name}.#{attr.name} is not defined" unless respond_to?(attr.name)

        v = public_send(attr.name)
        v = attr.convert_to_pb(v)

        if attr.required && attr.field_descriptor.default == v
          raise ::Pb::Serializer::ValidationError, "#{object.class.name}##{attr.name} is required"
        end

        next if v.nil?

        if attr.oneof?
          if oneof_set.include?(attr.oneof)
            raise ::Pb::Serializer::ConflictOneofError, "#{object.class.name}##{attr.name} is oneof attribute"
          end
          oneof_set << attr.oneof
        end

        if attr.repeated?
          o.public_send(attr.name).push(*v)
        else
          o.public_send("#{attr.name}=", v)
        end
      end

      self.class.oneofs.each do |oneof|
        next if oneof_set.include?(oneof.name)
        next unless oneof.required?
        raise ::Pb::Serializer::ValidationError, "#{object.class.name}##{oneof.name} is required"
      end

      o
    end

    module ClassMethods
      attr_reader :message_class
      def message(klass)
        @message_class = klass
      end

      # @param name [Symbol] An attribute name
      # @param required [Boolean] Set true if this attribute should not zero-value
      # @param serializer [Class] A serializer class for this attribute
      def attribute(name, required: false, serializer: nil)
        fd = message_class.descriptor.find { |fd| fd.name.to_sym == name }
        raise ::Pb::Serializer::UnknownFieldError, "#{name} is not defined in #{message_class.name}" unless fd

        attr = ::Pb::Serializer::Attribute.new(
          name: name,
          required: required,
          serializer_class: serializer,
          field_descriptor: fd,
          oneof: @current_oneof&.name,
        )

        @attr_by_name ||= {}
        @attr_by_name[name] = attr

        define_method attr.name do
          object.public_send(attr.name) # FIXME: This does not work without ::Pb::Serializer::Base
        end

        dependency # FIXME
        computed attr.name
      end

      # @param object [Object, Array]
      # @param message_class [Class]
      def serialize(object, with: nil)
        if self < ::Pb::Serializer::Base
          new(object).to_pb
        else
          object.to_pb
        end
      end

      def oneof(name, required: true)
        @oneof_by_name ||= {}
        @current_oneof = ::Pb::Serializer::Oneof.new(
          name: name,
          required: required,
          attributes: [],
        )
        yield
        @oneof_by_name[name] = @current_oneof
        @current_oneof = nil
      end

      # @param fd [Google::Protobuf::FieldDescriptor] a field descriptor
      # @return [Pb::Serializer::Attribute, nil]
      def find_attribute_by_field_descriptor(fd)
        @attr_by_name[fd.name.to_sym]
      end

      def oneofs
        @oneof_by_name&.values || []
      end
    end
  end
end
