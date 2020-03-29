# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: spec/fixtures/oneof.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("spec/fixtures/oneof.proto", :syntax => :proto3) do
    add_message "example.oneof.User" do
      optional :name, :string, 1
      repeated :accounts, :message, 2, "example.oneof.Account"
    end
    add_message "example.oneof.Account" do
      oneof :account do
        optional :github, :message, 1, "example.oneof.GithubAccount"
        optional :twitter, :message, 2, "example.oneof.TwitterAccount"
      end
    end
    add_message "example.oneof.GithubAccount" do
      optional :login, :string, 1
    end
    add_message "example.oneof.TwitterAccount" do
      optional :login, :string, 1
    end
  end
end

module TestFixture
  module Oneof
    User = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("example.oneof.User").msgclass
    Account = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("example.oneof.Account").msgclass
    GithubAccount = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("example.oneof.GithubAccount").msgclass
    TwitterAccount = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("example.oneof.TwitterAccount").msgclass
  end
end