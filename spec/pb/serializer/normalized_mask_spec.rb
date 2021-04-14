RSpec.describe Pb::Serializer::NormalizedMask do
  describe '.build' do
    subject { Pb::Serializer::NormalizedMask.build(input) }

    context 'when the input is a symbol' do
      let(:input) { :foo }
      it { is_expected.to match({ foo: {} }) }
    end

    context 'when the input is an array' do
      let(:input) { [:foo, bar: :baz, qux: [:quux]] }
      it { is_expected.to match({ foo: {}, bar: { baz: {} }, qux: { quux: {} } }) }

      context 'when the input has same hash keys' do
        let(:input) do
          [
            { foo: :bar },
            { foo: [:baz] },
            {
              foo: [
                { qux: [:quux] },
                { qux: [:corge] },
              ],
            },
          ]
        end
        let(:normalized) do
          {
            foo: {
              bar: {},
              baz: {},
              qux: { quux: {}, corge: {} },
            },
          }
        end
        it { is_expected.to match normalized }
      end
    end

    context 'when the input is a google.protobuf.FieldMask' do
      let(:input) do
        Google::Protobuf::FieldMask.new(paths: [
          "foo",
          "bar.baz",
          "bar.qux.quux",
        ])
      end
      it { is_expected.to match({ foo: {}, bar: { baz: {}, qux: { quux: {} } } }) }
    end
  end
end
