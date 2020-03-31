RSpec.describe 'allow_nil option' do
  include DBHelper

  module self::Sandbox
    class Message < Struct.new(
      :required_int32,
      :required_int32val,
      :optional_int32,
      :optional_int32val,
      :required_repeated_int32,
      :optional_repeated_int32,
      :required_oneof_int32,
      :required_oneof_int64,
      :optional_oneof_int32,
      :optional_oneof_int64,
      keyword_init: true,
    ); end
    class MessageSerializer < Pb::Serializer::Base
      message TestFixture::AllowNil::Message

      attribute :required_int32
      attribute :required_int32val
      attribute :optional_int32,          allow_nil: true
      attribute :optional_int32val,       allow_nil: true
      attribute :required_repeated_int32
      attribute :optional_repeated_int32, allow_nil: true

      oneof :required_oneof do
        attribute :required_oneof_int32
        attribute :required_oneof_int64
      end

      oneof :optional_oneof, allow_nil: true do
        attribute :optional_oneof_int32
        attribute :optional_oneof_int64
      end
    end
  end

  let(:sandbox) { self.class::Sandbox }
  let(:message) do
    sandbox::Message.new(
      required_int32: 1,
      required_int32val: 2,
      optional_int32: 3,
      optional_int32val: 4,
      required_repeated_int32: [5, 5],
      optional_repeated_int32: [6, 6],
      required_oneof_int32: 7,
      optional_oneof_int32: 9,
    )
  end
  subject { sandbox::MessageSerializer.new(message).to_pb }

  it 'raises an error when required primitive is nil' do
    message.required_int32 = nil
    expect { subject }.to raise_error Pb::Serializer::ValidationError
  end

  it 'does not raise an error when required primitive is zero value' do
    message.required_int32 = 0
    expect { subject }.to_not raise_error
  end

  it 'does raise an error when primitive allowed nil is nil' do
    message.optional_int32 = nil
    expect { subject }.to_not raise_error
  end

  it 'raises an error when required message is nil' do
    message.required_int32val = nil
    expect { subject }.to raise_error Pb::Serializer::ValidationError
  end

  it 'does not raise an error when optional primitive is nil' do
    message.optional_int32 = nil
    expect { subject }.to_not raise_error
  end

  it 'does not raise an error when optional message is nil' do
    message.optional_int32val = nil
    expect { subject }.to_not raise_error
  end

  it 'raises an error when required repeated field is nil' do
    message.required_repeated_int32 = nil
    expect { subject }.to raise_error Pb::Serializer::ValidationError
  end

  it 'does not raise an error when required repeated field is empty' do
    message.required_repeated_int32 = []
    expect { subject }.to_not raise_error
  end

  it 'does not raise an error when optional repeated field is nil' do
    message.optional_repeated_int32 = nil
    expect { subject }.to_not raise_error
  end

  it 'raises an error when required oneof fields are nil' do
    message.required_oneof_int32 = nil
    message.required_oneof_int64 = nil
    expect { subject }.to raise_error Pb::Serializer::ValidationError
  end

  it 'does not raise an error when optional oneof fields are nil' do
    message.optional_oneof_int32 = nil
    message.optional_oneof_int64 = nil
    expect { subject }.to_not raise_error
  end
end
