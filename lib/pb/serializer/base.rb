module Pb
  module Serializer
    class Base
      def self.inherited(base)
        base.include ::Pb::Serializable
        base.singleton_class.prepend Hook
      end

      attr_reader :object

      def initialize(object, *)
        @object = object
      end

      # @private
      module Hook
        def define_primary_loader(name, &block)
          class_eval <<~RUBY
            module PbSerializerDefinePrimaryLoaderPrependMethods
              def initialize(*args)
                super
                @#{name} = object
              end
            end

            prepend PbSerializerDefinePrimaryLoaderPrependMethods
          RUBY

          super
        end
      end
    end
  end
end
