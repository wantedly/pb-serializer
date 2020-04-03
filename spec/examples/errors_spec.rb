RSpec.describe 'errors' do
  it 'raises an error when declare an attribute without message specification' do
    expect {
      Class.new(Pb::Serializer::Base) do
        attribute :body
      end
    }.to raise_error Pb::Serializer::MissingMessageTypeError
  end

  it 'raises an error when unknown option is specified' do
    expect {
      Class.new(Pb::Serializer::Base) do
        message TestFixture::Simple::Message

        attribute :body, foo: :bar
      end
    }.to raise_error Pb::Serializer::InvalidOptionError
  end

  it 'raises an error when unknown fied is declared' do
    expect {
      Class.new(Pb::Serializer::Base) do
        message TestFixture::Simple::Message

        attribute :foo
      end
    }.to raise_error Pb::Serializer::UnknownFieldError
  end

  it 'raises an error when attribute declaration is missed' do
    klass = Class.new(Pb::Serializer::Base) do
      message TestFixture::Simple::Message
    end
    expect { klass.new(Struct.new(:body).new('foo')).to_pb }.to raise_error Pb::Serializer::MissingFieldError
  end
end
