module Pb
  module Serializer
    class Base
      def self.inherited(base)
        base.include ::Pb::Serializable
      end

      attr_reader :object

      def initialize(object)
        @object = object
      end
    end
  end
end
