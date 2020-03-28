module Pb
  module Serializer
    class Attribute < Struct.new(
      :name,
      :required,
      :serializer_class,
      :field_descriptor,
      :oneof,
      keyword_init: true,
    )

      # @return [Boolean]
      def required?
        required
      end

      # @return [Boolean]
      def repeated?
        field_descriptor.label == :repeated
      end

      def oneof?
        !oneof.nil?
      end

      # @param v [Object]
      def convert_to_pb(v, should_repeat: repeated?)
        return v.map { |i| convert_to_pb(i, should_repeat: false) } if should_repeat

        case field_descriptor.type
        when :message
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
            return nil if v.nil?
            return serializer_class.new(v).to_pb if serializer_class
            return v.to_pb if v.kind_of?(::Pb::Serializable)

            raise "serializer was not found for #{field_descriptor.submsg_name}"
          end
        else
          v.nil? ? field_descriptor.default : v
        end
      end
    end
  end
end
