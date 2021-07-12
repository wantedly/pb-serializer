# Pb::Serializer
[![CI](https://github.com/wantedly/pb-serializer/workflows/CI/badge.svg?branch=master)](https://github.com/wantedly/pb-serializer/actions?query=workflow%3ACI+branch%3Amaster)
[![codecov](https://codecov.io/gh/wantedly/pb-serializer/branch/master/graph/badge.svg)](https://codecov.io/gh/wantedly/pb-serializer)
[![Gem Version](https://badge.fury.io/rb/pb-serializer.svg)](https://badge.fury.io/rb/pb-serializer)
[![License](https://img.shields.io/github/license/wantedly/pb-serializer)](./LICENSE)

`Pb::Serializer` is Protocol Buffers serializer for Ruby objects.

[日本語版 README](./README.ja.md)

## Features

- Declarative APIs such as [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers)
- Automatic conversion to [Well-Known Types](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf) (e.g. `google.protobuf.Uint64Value`)
- Support for GraphQL-like selective field fetching using [`google.protobuf.FieldMask`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask).
  - When combined with [ComputedModel](https://github.com/wantedly/computed_model), APIs with complex logic and dependencies can be implemented declaratively.


## Usage

The following is an example of a message definition and ActiveRecord model for Protocol Buffers.

```proto
syntax = "proto3";

package example;

option ruby_package = "ExamplesPb";

message User {
  uint64 id = 1;
  string name = 2;
}
```

```ruby
# Schema: [id(integer), name(string)]
class User < ActiveRecord::Base
end
```

Implements a PbSerializer for the `User` message defined in `.proto`.
You need to declare the generated class and all defined fields in the PbSerializer.

```ruby
class UserPbSerializer < Pb::Serializer::Base
  message ExamplesPb::User

  attribute :id
  attribute :name
end
```

You can serialize Ruby objects to protobuf message object with the implemented PbSerializer.

```ruby
user = User.find(123)
UserPbSerializer.new(user).to_pb
# => <ExamplesPb::User: id: 123, name: "someuser">
```

The value of each attribute is determined from the PbSerializer instance or the object passed to the constructor.

## Next read

- [Examples](./docs/examples.md)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pb-serializer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pb-serializer

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/izumin5210/pb-serializer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pb::Serializer project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/izumin5210/pb-serializer/blob/master/CODE_OF_CONDUCT.md).
