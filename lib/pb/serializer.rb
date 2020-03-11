require "pb/serializer/version"

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
    def self.included(base)
      base.extend ClassMethods
    end

    def serialize(object)
      h =
        self.class.message_class.descriptor.each_with_object({}) do |d, o|
          n = d.name.to_sym

          next if d.label == :repeated # TODO

          obj = object

          if self.class.delegated_attrs.key?(n)
            obj = obj.public_send(self.class.delegated_attrs[n])
          end
          v =
            if respond_to?(n)
              public_send(n)
            elsif obj.respond_to?(n)
              obj.public_send(n)
            end
          o[n] =
            case d.type
            when :message
              case d.submsg_name
              when 'google.protobuf.StringValue'
                case v
                when nil;    nil
                when String; Google::Protobuf::StringValue.new(value: v)
                else raise # FIXME: invalid type
                end
              when 'google.protobuf.Timestamp'
                t =
                  case v
                  when nil;            nil
                  when Time;           v
                  when Date, DateTIme; v.to_time
                  when String;         Time.parse(v)
                  else raise # FIXME: invalid type
                  end
                t.nil? ? nil : Google::Protobuf::Timestamp.new(seconds: t.to_i, nanos: t.nsec)
              else
                # TODO: Support other well-known types
                next
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
