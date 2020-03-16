module Pb
  module Serializable
    class << self
      def included(base)
        base.extend ClassMethods
      end

      # @param [Google::Protobuf::Descriptor]
      # @return [nil, Sserializable]
      def find_serializable(d)
        @serializables[d.name]
      end

      # @param [Serializable]
      def register_serializable(s)
        @serializables ||= {}
        @serializables[s.message_class.descriptor.name] = s
        # TODO: check dupliication
      end
    end

    def to_pb
      ::Pb::Serializer.serialize(self)
    end

    class Attribute < Struct.new(:name, :required, keyword_init: true); end

    module ClassMethods
      attr_reader :message_class
      def message(klass)
        @message_class = klass
        Serializable.register_serializable(self)
      end

      # @param [Symbol] attr An attribute name
      # @param [Boolean] required Set true if this attribute should not zero-value
      def attribute(attr, required: false)
        @attr_by_name ||= {}
        @attr_by_name[attr] = Attribute.new(name: attr, required: required)

        define_method attr do
          obj, key = object, attr

          if self.class.delegated_attrs.has_key?(key)
            obj = obj.public_send(self.class.delegated_attrs[key])
          end

          obj.public_send(key)
        end
      end

      # @param [Symbol] attr Attribute name
      # @return [Boolean]
      def required?(name)
        @attr_by_name[name]&.required || false
      end

      def depends(**args)
        @last_depends = args
      end

      def delegates(*attrs, to:)
        puts "delegates: #{attrs}, to: #{to}"
        attrs.each do |attr|
          delegated_attrs[attr] = to
        end
      end

      def method_added(name)
        super

        dep = @last_depends
        @last_depends = nil
        return unless dep

        return if private_method_defined?(name)

        puts "depends: #{name}, on: #{dep}"
        # TODO: not implemented
      end

      def delegated_attrs
        @delegated_attrs ||= {}
      end
    end
  end
end
