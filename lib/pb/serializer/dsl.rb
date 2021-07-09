module Pb
  module Serializer
    module Dsl
      def message(klass)
        @message_class = klass
      end

      # @param name [Symbol] An attribute name
      # @param [Hash] opts options
      # @option opts [Boolean] :allow_nil Set true if this attribute allow to be nil
      # @option opts [Class] :serializer A serializer class for this attribute
      # @option opts [String, Symbol, Proc] :if A method, proc or string to call to determine to serialize this field
      def attribute(name, opts = {})
        raise ::Pb::Serializer::MissingMessageTypeError, "message specificaiton is missed" unless message_class

        fd = message_class.descriptor.find { |fd| fd.name.to_sym == name }

        raise ::Pb::Serializer::UnknownFieldError, "#{name} is not defined in #{message_class.name}" unless fd

        attr = ::Pb::Serializer::Attribute.new(
          name: name,
          options: opts,
          field_descriptor: fd,
          oneof: @current_oneof&.name,
        )

        @attr_by_name ||= {}
        @attr_by_name[name] = attr

        define_method attr.name do
          primary_object.public_send(attr.name)
        end
      end

      # @param names [Array<Symbol>] Attribute names to be ignored
      def ignore(*names)
        names.each do |name|
          attribute name, ignore: true
        end
      end

      def oneof(name, allow_nil: false)
        @oneof_by_name ||= {}
        @current_oneof = ::Pb::Serializer::Oneof.new(
          name: name,
          allow_nil: allow_nil,
          attributes: [],
        )
        yield
        @oneof_by_name[name] = @current_oneof
        @current_oneof = nil
      end

      attr_reader :message_class

      # @param fd [Google::Protobuf::FieldDescriptor] a field descriptor
      # @return [Pb::Serializer::Attribute, nil]
      def find_attribute_by_field_descriptor(fd)
        (@attr_by_name || {})[fd.name.to_sym]
      end

      def oneofs
        @oneof_by_name&.values || []
      end
    end
  end
end
