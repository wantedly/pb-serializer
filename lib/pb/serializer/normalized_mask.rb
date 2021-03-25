module Pb::Serializer
  class NormalizedMask < ::Hash
    class << self
      # @param [Google::Protobuf::FieldMask, Symbol, Array<(Symbol,Hash)>, Hash{Symbol=>(Array,Symbol,Hash)}]
      # @return [Hash{Symbol=>Hash}]
      def build(input)
        return input if input.kind_of? self

        normalized = new

        case input
        when Google::Protobuf::FieldMask
          normalized = normalize_mask_paths(input.paths)
        when Array
          input.each do |v|
            deep_merge!(normalized, build(v))
          end
        when Hash
          input.each do |k, v|
            normalized[k] ||= new
            deep_merge!(normalized[k], build(v))
          end
        when Symbol
          normalized[input] ||= new
        else
          raise "not supported field mask type: #{input.class}"
        end

        normalized
      end

      private

      # @param [Array<String>]
      # @return [Hash{Symbol=>Hash}]
      def normalize_mask_paths(paths)
        paths_by_key = {}

        paths.each do |path|
          key, rest = path.split('.', 2)
          paths_by_key[key.to_sym] ||= []
          paths_by_key[key.to_sym].push(rest) if rest && !rest.empty?
        end

        paths_by_key.keys.each_with_object(new) do |key, normalized|
          normalized[key] = normalize_mask_paths(paths_by_key[key])
        end
      end

      def deep_merge!(h1, h2)
        h1.merge!(h2) do |_k, v1, v2|
          if v1.kind_of?(Hash) && v2.kind_of?(Hash)
            deep_merge!(v1, v2)
          else
            v2
          end
        end
      end
    end
  end
end
