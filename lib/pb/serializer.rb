require "pb/serializer/version"
require "the_pb"

module Pb
  module Serializer
    class Base
      def self.inherited(base)
        base.include Serializable
      end

      attr_reader :object

      def initialize(object)
        @object = object
      end

      def to_pb
        serialize(object)
      end
    end
  end

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

    def serialize(object)
      h =
        self.class.message_class.descriptor.each_with_object({}) do |d, o|
          n = d.name.to_sym

          next if d.label == :repeated # TODO

          v =
            if respond_to?(n)
              public_send(n)
            else
              raise "#{self.class.name}.#{n} is not defined"
            end
          o[n] =
            case d.type
            when :message
              case d.submsg_name
              when "google.protobuf.Timestamp" then   Pb.to_timestamp(v)
              when "google.protobuf.StringValue" then Pb.to_strval(v)
              when "google.protobuf.Int32Value" then  Pb.to_int32val(v)
              when "google.protobuf.Int64Value" then  Pb.to_int64val(v)
              when "google.protobuf.UInt32Value" then Pb.to_uint32val(v)
              when "google.protobuf.UInt64Value" then Pb.to_uint64val(v)
              when "google.protobuf.FloatValue" then  Pb.to_floatval(v)
              when "google.protobuf.DoubleValue" then Pb.to_doubleval(v)
              when "google.protobuf.BoolValue" then   Pb.to_boolval(v)
              when "google.protobuf.BytesValue" then  Pb.to_bytesval(v)
              else
                serializable_class = Serializable.find_serializable(d.subtype)
                raise "serializer was not found for #{d.submsg_name}" if serializable_class.nil?

                next if v.nil?

                if serializable_class < ::Pb::Serializer::Base
                  serializable_class.new(v).to_pb
                else
                  serializable_class.new.serialize(v)
                end
              end
            else
              v
            end
        end
      self.class.message_class.new(**h)
    end

    module ClassMethods
      attr_reader :message_class
      def message(klass)
        @message_class = klass
        Serializable.register_serializable(self)
      end

      # @param [Symbol] attr An attribute name
      # @param [Boolean] required Set true if this attribute should not zero-value
      def attribute(attr, required: false)
        # TODO: Handle `required` param

        define_method attr do
          obj, key = object, attr

          if self.class.delegated_attrs.has_key?(key)
            obj = obj.public_send(self.class.delegated_attrs[key])
          end

          obj.public_send(key)
        end
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
