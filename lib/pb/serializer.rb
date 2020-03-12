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

          if self.class.delegated_attrs.key?(n) && object.respond_to?(self.class.delegated_attrs[n])
            object = object.public_send(self.class.delegated_attrs[n])
          end
          v =
            if respond_to?(n)
              public_send(n)
            elsif object.respond_to?(n)
              object.public_send(n)
            end

          o[n] = if d.label == :repeated
                   v.map { |vv| convert_pb_message(d, vv) }
                 else
                   convert_pb_message(d, v)
                 end
        end

      self.class.message_class.new(**h)
    end

    def convert_pb_message(d, v)
      case d.type
      when :message
        case d.submsg_name
        when 'google.protobuf.StringValue'
          v.nil? ? nil : Google::Protobuf::StringValue.new(value: v)
        when 'google.protobuf.Timestamp'
          # TODO: Support other well-known types
          return
        else
          if v.nil?
            nil
          else
            klass = ::Google::Protobuf::DescriptorPool.generated_pool.lookup(d.submsg_name).msgclass
            value = klass.new.to_h.keys.map {|f| [f, v.public_send(f)] }.to_h
            klass.new(**value)
          end
        end
      else
        v
      end
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

      def attribute(name)
        class_eval <<~RUBY
          def #{name}
            object.#{name}
          end
        RUBY
      end

      def attributes(*names)
        names.map {|name| attribute(name) }
      end
    end
  end
end
