RSpec.describe 'ignore attributes' do
  module self::Sandbox
    class Message
      def body
        throw 'not implemented'
      end
    end

    class MessageSerializer < Pb::Serializer::Base
      message TestFixture::Simple::Message

      ignore :body
    end
  end

  let(:sandbox) { self.class::Sandbox }
  let(:message) { sandbox::Message.new }
  let(:serializer) { sandbox::MessageSerializer.new(message) }
  let(:pb) { serializer.to_pb }

  it 'returns empty when \`ignore\` directive used' do
    expect(pb).to be_kind_of TestFixture::Simple::Message
    expect(pb.body).to eq ""
  end
end
