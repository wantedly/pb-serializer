module Pb
  module Serializable
    extend ActiveSupport::Concern
    include ComputedModel::Model

    def self.included(base)
      base.include Pb::Serializer::ComputedModelSupport
      base.extend Pb::Serializer::Dsl
    end

    # @param with [
    #   Google::Protobuf::FieldMask,
    #   Array<(Symbol, Hash)>,
    #   Hash{Symbol=>(Array,Symbol,Hash)},
    # ]
    def to_pb(with: nil)
      with ||= ::Pb::Serializer.build_default_mask(self.class.message_class.descriptor)
      with = ::Pb::Serializer.normalize_mask(with)

      oneof_set = []

      o = self.class.message_class.new
      self.class.message_class.descriptor.each do |fd|
        attr = self.class.find_attribute_by_field_descriptor(fd)

        unless attr
          msg = "#{self.class.message_class.name}.#{fd.name} is missed in #{self.class.name}"

          case Pb::Serializer.configuration.missing_field_behavior
          when :raise then raise ::Pb::Serializer::MissingFieldError, msg
          when :warn  then Pb::Serializer.logger.warn msg
          end

          next
        end

        next unless with.key?(attr.name)
        next unless attr.serializable?(self)

        raise "#{self.name}.#{attr.name} is not defined" unless respond_to?(attr.name)

        v = public_send(attr.name)
        v = attr.convert_to_pb(v, with: with[attr.name])

        if attr.oneof?
          if !v.nil?
            if oneof_set.include?(attr.oneof)
              raise ::Pb::Serializer::ConflictOneofError, "#{primary_object.class.name}##{attr.name} is oneof attribute"
            end
            oneof_set << attr.oneof
          end
        elsif !attr.allow_nil? && v.nil?
          raise ::Pb::Serializer::ValidationError, "#{primary_object.class.name}##{attr.name} is required"
        end

        next if v.nil?

        if attr.repeated?
          o.public_send(attr.name).push(*v)
        else
          o.public_send("#{attr.name}=", v)
        end
      end

      self.class.oneofs.each do |oneof|
        next if oneof_set.include?(oneof.name)
        next if oneof.allow_nil?
        raise ::Pb::Serializer::ValidationError, "#{primary_object.class.name}##{oneof.name} is required"
      end

      o
    end

    module ClassMethods
      # @param with [Array, Hash, Google::Protobuf::FieldMask, nil]
      # @return [Array]
      def bulk_load_and_serialize(with: nil, **args)
        bulk_load(with: with, **args).map { |s| s.to_pb(with: with) }
      end

      def bulk_load(with: nil, **args)
        with ||= ::Pb::Serializer.build_default_mask(message_class.descriptor)
        with = ::Pb::Serializer.normalize_mask(with)
        with = __pb_serializer_filter_only_computed_model_attrs(with)

        primary_object_name = __pb_serializer_primary_model_name
        if primary_object_name
          (with[primary_object_name] ||= []) << true
        elsif self < Serializer::Base
          (with[:object] ||= []) << true
        end

        bulk_load_and_compute(with, **args)
      end
    end
  end
end
