RSpec.describe 'conditional attributes' do
  module self::Sandbox
    class Message < Struct.new(:body, keyword_init: true); end

    class MessageSerializerWithProcCond < Pb::Serializer::Base
      message TestFixture::Simple::Message

      attribute :body, if: -> { ok }

      attr_accessor :ok
    end

    class MessageSerializerWithSymbolCond < Pb::Serializer::Base
      message TestFixture::Simple::Message

      attribute :body, if: :ok?

      attr_accessor :ok

      def ok?; !!ok; end
    end

    class MessageSerializerWithStringCond < Pb::Serializer::Base
      message TestFixture::Simple::Message

      attribute :body, if: 'ok?'

      attr_accessor :ok

      def ok?; !!ok; end
    end
  end

  let(:sandbox) { self.class::Sandbox }
  let(:message) { sandbox::Message.new(body: "Hello") }

  context 'when specified a proc to `if` option' do
    let(:serializer) { sandbox::MessageSerializerWithProcCond.new(message) }
    let(:pb) { serializer.to_pb }

    it 'serializes a field when the proc returns truthy value' do
      serializer.ok = true
      expect(pb).to be_kind_of TestFixture::Simple::Message
      expect(pb.body).to eq message.body
    end

    it 'serializes a field when the proc returns truthy value' do
      serializer.ok = false
      expect(pb).to be_kind_of TestFixture::Simple::Message
      expect(pb.body).to eq ""
    end
  end

  context 'when specified a symbol to `if` option' do
    let(:serializer) { sandbox::MessageSerializerWithSymbolCond.new(message) }
    let(:pb) { serializer.to_pb }

    it 'serializes a field when the proc returns truthy value' do
      serializer.ok = true
      expect(pb).to be_kind_of TestFixture::Simple::Message
      expect(pb.body).to eq message.body
    end

    it 'serializes a field when the proc returns truthy value' do
      serializer.ok = false
      expect(pb).to be_kind_of TestFixture::Simple::Message
      expect(pb.body).to eq ""
    end
  end

  context 'when specified a string to `if` option' do
    let(:serializer) { sandbox::MessageSerializerWithStringCond.new(message) }
    let(:pb) { serializer.to_pb }

    it 'serializes a field when the proc returns truthy value' do
      serializer.ok = true
      expect(pb).to be_kind_of TestFixture::Simple::Message
      expect(pb.body).to eq message.body
    end

    it 'serializes a field when the proc returns truthy value' do
      serializer.ok = false
      expect(pb).to be_kind_of TestFixture::Simple::Message
      expect(pb.body).to eq ""
    end
  end
end
