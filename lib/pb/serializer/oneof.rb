module Pb
  module Serializer
    class Oneof < Struct.new(
      :name,
      :required,
      :attributes,
      keyword_init: true,
    )
      # @return [Boolean]
      def required?
        required
      end
    end
  end
end
