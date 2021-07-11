module Pb
  module Serializer
    # @private
    module ComputedModelSupport
      def self.included(base)
        base.singleton_class.prepend Hook
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
        attr_accessor :__pb_serializer_primary_model_name

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

        # @param with [Array]
        private def __pb_serializer_filter_only_computed_model_attrs(with)
          with.reject { |c| (__pb_serializer_attrs & (c.kind_of?(Hash) ? c.keys : [c])).empty? }
        end

        private def __pb_serializer_attrs
          @__pb_serializer_attrs ||= Set.new
        end
      end
    end
  end
end
