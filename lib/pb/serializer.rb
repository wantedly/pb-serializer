require "pb/serializer/version"
require "the_pb"
require "computed_model"

require "pb/serializable"
require "pb/serializer/base"
require "pb/serializer/attribute"
require "pb/serializer/oneof"

module Pb
  module Serializer
    class Error < StandardError; end
    class UnknownFieldError < Error; end
    class ValidationError < Error; end

    class << self
      # @param [Google::Protobuf::Descriptor]
      def build_default_mask(descriptor)
        set =
          descriptor.each_with_object(Set[]) do |fd, m|
            case fd.type
            when :message
              case fd.submsg_name
              when "google.protobuf.Timestamp", 
                "google.protobuf.StringValue",
                "google.protobuf.Int32Value" ,
                "google.protobuf.Int64Value" ,
                "google.protobuf.UInt32Value",
                "google.protobuf.UInt64Value",
                "google.protobuf.FloatValue" ,
                "google.protobuf.DoubleValue",
                "google.protobuf.BoolValue"  ,
                "google.protobuf.BytesValue" then m << fd.name.to_sym
              else
                m << { fd.name.to_sym => build_default_mask(fd.subtype) }
              end
            else
              m << fd.name.to_sym
            end
          end
        set.to_a
      end
    end
  end
end
