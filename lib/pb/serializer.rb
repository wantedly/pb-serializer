require "pb/serializer/version"
require "the_pb"

require "pb/serializable"

module Pb
  module Serializer
    class ValidationError < StandardError; end

    class Base
      def self.inherited(base)
        base.include Serializable
      end

      attr_reader :object

      def initialize(object)
        @object = object
      end
    end
  end
end
