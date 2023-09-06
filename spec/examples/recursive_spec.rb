RSpec.describe 'recursive models' do
  module self::Sandbox
    class StringListSerializer < Pb::Serializer::Base
      message TestFixture::Recursive::StringList

      attribute :car
      attribute :cdr, allow_nil: true, serializer: StringListSerializer
    end

    StringList = Struct.new(:car, :cdr)
  end

  let(:sandbox) { self.class::Sandbox }

  it "serializes recursive ruby object into protobuf type" do
    l = sandbox::StringList.new(
      "Alpha",
      sandbox::StringList.new(
        "Bravo",
        sandbox::StringList.new(
          "Charlie",
          nil,
        ),
      ),
    )
    pb = sandbox::StringListSerializer.new(l).to_pb

    expect(pb).to be_a(TestFixture::Recursive::StringList)
    expect(pb.car).to eq "Alpha"
    expect(pb.cdr.car).to eq "Bravo"
    expect(pb.cdr.cdr.car).to eq "Charlie"
  end
end
