module Pb
  module Serializable
    module Dsl
      # @api private
      class Oneof < Struct.new(
        :name,
        :allow_nil,
        :attributes,
        keyword_init: true,
      )
        # @return [Boolean]
        def allow_nil?
          allow_nil
        end
      end
    end
  end
end
