module Pb
  module Serializer
    class Attribute < Struct.new(
      :name,
      :options,
      :field_descriptor,
      :oneof,
      keyword_init: true,
    )

      ALLOWED_OPTIONS = Set[:allow_nil, :if, :serializer].freeze

      def initialize(options:, **)
        super

        unknown_options = options.keys.to_set - ALLOWED_OPTIONS
        unless unknown_options.empty?
          raise InvalidAttributeOptionError, "unknown options are specified in #{name} attribute: #{unknown_options.to_a}"
        end
      end

      # @return [Boolean]
      def allow_nil?
        options.fetch(:allow_nil, false)
      end

      # @return [Class]
      def serializer_class
        options[:serializer]
      end

      # @return [Boolean]
      def repeated?
        field_descriptor.label == :repeated
      end

      # @return [Boolean]
      def serializable?(s)
        cond = options[:if]

        return true unless cond

        case cond
        when String, Symbol; then s.send(cond)
        when Proc;           then s.instance_exec(&cond)
        else raise InvalidAttributeOptionError, "`if` option can accept only Symbol, String or Proc. but got #{cond.class}"
        end
      end

      def oneof?
        !oneof.nil?
      end

      # @param v [Object]
      # @param with [Pb::Serializer::NormalizedMask]
      def convert_to_pb(v, with: nil, should_repeat: repeated?)
        return nil if v.nil?
        return v.map { |i| convert_to_pb(i, should_repeat: false, with: with) } if should_repeat

        case field_descriptor.type
        when :message
          if v.class < Google::Protobuf::MessageExts && v.class.descriptor.name == field_descriptor.submsg_name
            return v
          end

          case field_descriptor.submsg_name
          when "google.protobuf.Timestamp"   then Pb.to_timestamp(v)
          when "google.protobuf.StringValue" then Pb.to_strval(v)
          when "google.protobuf.Int32Value"  then Pb.to_int32val(v)
          when "google.protobuf.Int64Value"  then Pb.to_int64val(v)
          when "google.protobuf.UInt32Value" then Pb.to_uint32val(v)
          when "google.protobuf.UInt64Value" then Pb.to_uint64val(v)
          when "google.protobuf.FloatValue"  then Pb.to_floatval(v)
          when "google.protobuf.DoubleValue" then Pb.to_doubleval(v)
          when "google.protobuf.BoolValue"   then Pb.to_boolval(v)
          when "google.protobuf.BytesValue"  then Pb.to_bytesval(v)
          else
            return serializer_class.new(v).to_pb(with: with) if serializer_class
            return v.to_pb(with: with) if v.kind_of?(::Pb::Serializable)

            raise "serializer was not found for #{field_descriptor.submsg_name}"
          end
        else
          v.nil? ? field_descriptor.default : v
        end
      end
    end
  end
end
