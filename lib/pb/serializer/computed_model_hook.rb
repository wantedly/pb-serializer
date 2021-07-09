module Pb
  module Serializer
    module ComputedModelHook
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
    end
  end
end
