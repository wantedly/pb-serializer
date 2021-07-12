<!--
# @title 日本語版 README
-->

# Pb::Serializer

`Pb::Serializer` はRuby オブジェクトの Protocol Buffers シリアライザです。

[English version](./README.md)

## Features

- [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers) のような宣言的な API 
- [Well-Known Types](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf) への自動変換（例 `google.protobuf.Uint64Value`）
- [`google.protobuf.FieldMask`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask) を利用した、GraphQL のような選択的フィールド取得のサポート
  - [ComputedModel](https://github.com/wantedly/computed_model) と組み合わせることで、複雑なロジックと依存関係を持つ API も宣言的に実装できます


## Usage

以下のような Protocol Buffers のメッセージ定義および ActiveRecord モデルを例にします。

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

`.proto` で定義された `User` メッセージに対応する PbSerializer を実装します。
生成されたクラスと定義されているフィールドすべてを PbSerializer に宣言する必要があります。

```ruby
class UserPbSerializer < Pb::Serializer::Base
  message ExamplesPb::User

  attribute :id
  attribute :name
end
```

実装した PbSerializer で、Ruby オブジェクトを protobuf message object にシリアライズできます。

```ruby
user = User.find(123)
UserPbSerializer.new(user).to_pb
# => <ExamplesPb::User: id: 123, name: "someuser">
```

各 attribute の値は、PbSerializer インスタンス、もしくはコンストラクタに渡されたオブジェクト から決定されます。

## Next read

- [Examples](./docs/examples.md)
