RSpec.describe 'well-known types in google.protobuf' do
  include DBHelper

  module self::Sandbox
    class Message < Struct.new(
      :timestamp,
      :int32_value,
      :int64_value,
      :uint32_value,
      :uint64_value,
      :float_value,
      :double_value,
      :bool_value,
      :string_value,
      keyword_init: true
    )
    end
    class MessageSerializer < Pb::Serializer::Base
      message TestFixture::WellKnownTypes::Message

      attribute :timestamp
      attribute :int32_value
      attribute :int64_value
      attribute :uint32_value
      attribute :uint64_value
      attribute :float_value
      attribute :double_value
      attribute :bool_value
      attribute :string_value
    end
  end

  let(:sandbox) { self.class::Sandbox }

  it 'serializes ruby objects into protobuf well-known types' do
    t = Time.new
    pb = sandbox::MessageSerializer.new(sandbox::Message.new(
      timestamp: t,
      int32_value: 1,
      int64_value: 2,
      uint32_value: 3,
      uint64_value: 4,
      float_value: 5.6,
      double_value: 7.8,
      bool_value: true,
      string_value: "foobar",
    )).to_pb

    expect(pb.timestamp).to eq Pb.to_timestamp(t)
    expect(pb.int32_value).to eq Pb.to_int32val(1)
    expect(pb.int64_value).to eq Pb.to_int64val(2)
    expect(pb.uint32_value).to eq Pb.to_uint32val(3)
    expect(pb.uint64_value).to eq Pb.to_uint64val(4)
    expect(pb.float_value).to eq Pb.to_floatval(5.6)
    expect(pb.double_value).to eq Pb.to_doubleval(7.8)
    expect(pb.bool_value).to eq Pb.to_boolval(true)
    expect(pb.string_value).to eq Pb.to_strval("foobar")
  end

  it 'skips serializing when a value is already serialized' do
    t = Time.new
    pb = sandbox::MessageSerializer.new(sandbox::Message.new(
      timestamp: Pb.to_timestamp(t),
      int32_value: Pb.to_int32val(1),
      int64_value: Pb.to_int64val(2),
      uint32_value: Pb.to_uint32val(3),
      uint64_value: Pb.to_uint64val(4),
      float_value: Pb.to_floatval(5.6),
      double_value: Pb.to_doubleval(7.8),
      bool_value: Pb.to_boolval(true),
      string_value: Pb.to_strval("foobar"),
    )).to_pb

    expect(pb.timestamp).to eq Pb.to_timestamp(t)
    expect(pb.int32_value).to eq Pb.to_int32val(1)
    expect(pb.int64_value).to eq Pb.to_int64val(2)
    expect(pb.uint32_value).to eq Pb.to_uint32val(3)
    expect(pb.uint64_value).to eq Pb.to_uint64val(4)
    expect(pb.float_value).to eq Pb.to_floatval(5.6)
    expect(pb.double_value).to eq Pb.to_doubleval(7.8)
    expect(pb.bool_value).to eq Pb.to_boolval(true)
    expect(pb.string_value).to eq Pb.to_strval("foobar")
  end
end
