# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: spec/fixtures/allow_nil.proto

require 'google/protobuf'

require 'google/protobuf/wrappers_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("spec/fixtures/allow_nil.proto", :syntax => :proto3) do
    add_message "example.allow_nil.Message" do
      optional :required_int32, :int32, 1
      optional :optional_int32, :int32, 2
      optional :required_int32val, :message, 3, "google.protobuf.Int32Value"
      optional :optional_int32val, :message, 4, "google.protobuf.Int32Value"
      repeated :required_repeated_int32, :int32, 5
      repeated :optional_repeated_int32, :int32, 6
      oneof :required_oneof do
        optional :required_oneof_int32, :int32, 7
        optional :required_oneof_int64, :int32, 8
      end
      oneof :optional_oneof do
        optional :optional_oneof_int32, :int32, 9
        optional :optional_oneof_int64, :int32, 10
      end
    end
  end
end

module TestFixture
  module AllowNil
    Message = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("example.allow_nil.Message").msgclass
  end
end
