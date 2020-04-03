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
    class InvalidConfigurationError < Error; end
    class MissingMessageTypeError < Error; end
    class UnknownFieldError < Error; end
    class ValidationError < Error; end
    class ConflictOneofError < Error; end
    class InvalidAttributeOptionError < Error; end
    class MissingFieldError < Error; end

    class Configuration
      # @!attribute logger
      #   @return [Logger]
      attr_accessor :logger
      # @!attribute [r] missing_field_behavior
      #   @return [:raise, :warn, :ignore] default: `:raise`
      attr_reader :missing_field_behavior

      def initialize
        self.missing_field_behavior = :raise
        self.logger = Logger.new(STDOUT)
      end

      # @param v [:raise, :warn, :ignore]
      def missing_field_behavior=(v)
        @missing_field_behavior = v

        unless %i(raise warn ignore).include?(v)
          raise InvalidConfigurationError, "missing_field_behavior #{v} is not allowed"
        end
      end
    end

    class << self
      # @example
      #   Pb::Serializer.configuration do |c|
      #     c.missing_field_behavior = :raise  # :raise, :warn or :ignore (defualt: :raise)
      #   end
      # @yield [c]
      # @yieldparam [Configuration] config
      def configure
        yield configuration
      end

      # @return [Pb::Serializer::Configuration]
      def configuration
        @configuraiton ||= Configuration.new
      end

      # @return [Logger]
      def logger
        configuration.logger
      end

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
