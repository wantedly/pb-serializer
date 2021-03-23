module Pb
  module Serializable
    def self.included(base)
      base.extend ClassMethods
      base.include ComputedModel
      base.singleton_class.prepend Hook
    end

    # @param with [
    #   Google::Protobuf::FieldMask,
    #   Array<(Symbol, Hash)>,
    #   Hash{Symbol=>(Array,Symbol,Hash)},
    #   Pb::Serializer::NormalizedMask
    # ]
    def to_pb(with: nil)
      with ||= ::Pb::Serializer.build_default_mask(self.class.message_class.descriptor)
      with = ::Pb::Serializer::NormalizedMask.build(with)

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

    private def primary_object
      primary_object_name = self.class.__pb_serializer_primary_model_name
      if primary_object_name
        send(primary_object_name)
      elsif kind_of?(Serializer::Base)
        send(:object)
      else
        self
      end
    end

    module Hook
      def define_primary_loader(name)
        self.__pb_serializer_primary_model_name = name

        super
      end

      def computed(name)
        __pb_serializer_attrs << name

        super
      end

      def define_loader(name, **)
        __pb_serializer_attrs << name

        super
      end
    end

    module ClassMethods
      attr_reader :message_class
      attr_accessor :__pb_serializer_primary_model_name

      def message(klass)
        @message_class = klass
      end

      # @param name [Symbol] An attribute name
      # @param [Hash] opts options
      # @option opts [Boolean] :allow_nil Set true if this attribute allow to be nil
      # @option opts [Class] :serializer A serializer class for this attribute
      # @option opts [String, Symbol, Proc] :if A method, proc or string to call to determine to serialize this field
      def attribute(name, opts = {})
        raise ::Pb::Serializer::MissingMessageTypeError, "message specificaiton is missed" unless message_class

        fd = message_class.descriptor.find { |fd| fd.name.to_sym == name }

        raise ::Pb::Serializer::UnknownFieldError, "#{name} is not defined in #{message_class.name}" unless fd

        attr = ::Pb::Serializer::Attribute.new(
          name: name,
          options: opts,
          field_descriptor: fd,
          oneof: @current_oneof&.name,
        )

        @attr_by_name ||= {}
        @attr_by_name[name] = attr

        define_method attr.name do
          primary_object.public_send(attr.name)
        end
      end

      # @param with [Array, Hash, Google::Protobuf::FieldMask, nil]
      # @return [Array]
      def bulk_load_and_serialize(with: nil, **args)
        bulk_load(with: with, **args).map { |s| s.to_pb(with: with) }
      end

      def bulk_load(with: nil, **args)
        with ||= ::Pb::Serializer.build_default_mask(message_class.descriptor)
        with = ::Pb::Serializer::NormalizedMask.build(with)
        with = with.reject { |c| (__pb_serializer_attrs & (c.kind_of?(Hash) ? c.keys : [c])).empty? }

        bulk_load_and_compute(with, **args)
      end

      def oneof(name, allow_nil: false)
        @oneof_by_name ||= {}
        @current_oneof = ::Pb::Serializer::Oneof.new(
          name: name,
          allow_nil: allow_nil,
          attributes: [],
        )
        yield
        @oneof_by_name[name] = @current_oneof
        @current_oneof = nil
      end

      private def __pb_serializer_attrs
        @__pb_serializer_attrs ||= Set.new
      end

      # @param fd [Google::Protobuf::FieldDescriptor] a field descriptor
      # @return [Pb::Serializer::Attribute, nil]
      def find_attribute_by_field_descriptor(fd)
        (@attr_by_name || {})[fd.name.to_sym]
      end

      def oneofs
        @oneof_by_name&.values || []
      end
    end
  end
end
