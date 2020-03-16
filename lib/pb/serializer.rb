require "pb/serializer/version"
require "the_pb"

require "pb/serializable"
require "pb/serializer/base"

module Pb
  module Serializer
    class ValidationError < StandardError; end

    class << self
      def serialize(object)
        o = object.class.message_class.new
        object.class.message_class.descriptor.each do |fd|
          n = fd.name.to_sym

          next if fd.label == :repeated # TODO

          raise "#{object.class.name}.#{n} is not defined" unless object.respond_to?(n)

          v = object.public_send(n)
          v = convert_to_pb(v, fd)

          if object.class.required?(n) && fd.default == v
            raise ::Pb::Serializer::ValidationError, "#{object.class.name}##{n} is required"
          end

          o.public_send("#{n}=", v)
        end
        o
      end

      # @param [Object] v
      # @param [Google::Protobuf::FieldDescriptor] fd
      private def convert_to_pb(v, fd)
        case fd.type
        when :message
          case fd.submsg_name
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
            serializable_class = ::Pb::Serializable.find_serializable(fd.subtype)
            raise "serializer was not found for #{fd.submsg_name}" if serializable_class.nil?

            return nil if v.nil?

            if serializable_class < ::Pb::Serializer::Base
              serializable_class.new(v).to_pb
            else
              serializable_class.new.serialize(v)
            end
          end
        else
          v.nil? ? fd.default : v
        end
      end
    end
  end
end
