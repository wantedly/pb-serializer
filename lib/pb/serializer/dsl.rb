require 'pb/serializer/dsl/attribute'
require 'pb/serializer/dsl/oneof'

module Pb
  module Serializer
    module Dsl
      def message(klass)
        self.__pb_serializer_message_class = klass
      end

      # @param name [Symbol] An attribute name
      # @param [Hash] opts options
      # @option opts [Boolean] :allow_nil Set true if this attribute allow to be nil
      # @option opts [Class] :serializer A serializer class for this attribute
      # @option opts [String, Symbol, Proc] :if A method, proc or string to call to determine to serialize this field
      def attribute(name, opts = {})
        raise ::Pb::Serializer::MissingMessageTypeError, "message specificaiton is missed" unless __pb_serializer_message_class

        fd = __pb_serializer_message_class.descriptor.find { |fd| fd.name.to_sym == name }

        raise ::Pb::Serializer::UnknownFieldError, "#{name} is not defined in #{ __pb_serializer_message_class.name}" unless fd

        attr = Attribute.new(
          name: name,
          options: opts,
          field_descriptor: fd,
          oneof: @current_oneof&.name,
        )

        __pb_serializer_attr_by_name[name] = attr

        unless method_defined?(attr.name)
          define_method attr.name do
            primary_object.public_send(attr.name)
          end
        end
      end

      # @param names [Array<Symbol>] Attribute names to be ignored
      def ignore(*names)
        names.each do |name|
          attribute name, ignore: true
        end
      end

      def oneof(name, allow_nil: false)
        @current_oneof = Oneof.new(
          name: name,
          allow_nil: allow_nil,
          attributes: [],
        )
        yield
        __pb_serializer_oneof_by_name[name] = @current_oneof
        @current_oneof = nil
      end
    end
  end
end
