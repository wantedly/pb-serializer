# Examples

## Sub messages

```proto
message Post {
  uint64 id = 1;
  string title = 2;
  User author = 3;
}

message User {
  uint64 id = 1;
  string name = 2;
}
```

```ruby
# Schema: [id(integer), title(string), author_id(integer)]
class Book < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
end

# Schema: [id(integer), name(string)]
class User < ActiveRecord::Base
end
```

```ruby
class BookPbSerializer < Pb::Serializer::Base
  message ExamplesPb::Book

  attribute :id
  attribute :title
  attribute :author, serializer: UserPbSerializer
end

class UserPbSerializer < Pb::Serializer::Base
  message ExamplesPb::User

  attribute :id
  attribute :name
end
```

## Enum

```proto
message Conversation {
  uint64 id = 1;
  Status status = 3;

  enum Status {
    STATUS_UNSPECIFIED = 0;
    ARCHIVED = 1;
    ACTIVE = 2;
  }
}
```

```ruby
# https://api.rubyonrails.org/classes/ActiveRecord/Enum.html

# Schema: [id(integer), status(integer)]
class Conversation < ApplicationRecord
  enum status: { active: 0, archived: 1 }, _prefix: true
end
```

```ruby
# @!attribute [r] object
#   @return [Conversation]
class ConversationPbSerializer < Pb::Serializer::Base
  message ExamplesPb::Conversation

  attribute :status

  def status
    object.status.upcase.to_sym
  end
end
```

## Oneof

```proto
message Entry {
  oneof entry {
    Message message = 1;
    Comment comment = 2;
  }
}

message Message {
  // ...
}

message Comment {
  // ...
}
```

```ruby
# see https://api.rubyonrails.org/classes/ActiveRecord/DelegatedType.html

class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[Message Comment]
end

class Message < ApplicationRecord
  # ...
end

class Comment < ApplicationRecord
  # ...
end
```

```ruby
# @!attribute [r] object
#   @return [Entry]
class EntryPbSerializer < Pb::Serializer::Base
  message ExamplesPb::Entry

  oneof :entry do
    attribute :message, if: -> { object.message? }, serializer: MessagePbSerializer
    attribute :comment, if: -> { object.comment? }, serializer: CommentPbSerializer
  end
end

# @!attribute [r] object
#   @return [Message]
class MessagePbSerializer < Pb::Serializer::Base
  message ExamplesPb::Message

  # ...
end

# @!attribute [r] object
#   @return [Comment]
class CommentPbSerializer < Pb::Serializer::Base
  message ExamplesPb::Comment

  # ...
end
```

## Serializable model

```proto
message User {
  uint64 id = 1;
  string first_name = 2;
  string last_name = 3;
}
```

```ruby
# Schema: [id(integer), first_name(string), last_name(string)]
class User < ActiveRecord::Base
  include Pb::Serializable

  message ExamplesPb::User

  attribute :id
  attribute :first_name
  attribute :last_name
end
```

```ruby
User.find(123).to_pb
# => <ExamplesPb::User: id: 123, first_name: 'Masayuki', last_name: 'Izumi'>
```

## With FieldMask and ComputedModel

```proto
message User {
  uint64 id = 1;
  string first_name = 2;
  string last_name = 3;
  string full_name = 4;
}
```

```ruby
# Schema: [id(integer), first_name(string), last_name(string)]
class RawUser < ActiveRecord::Base
  self.table_name = 'users'
end

class User
  include ComputedModel::Model

  def initialize(raw_user)
    @raw_user = user
  end

  def self.batch_get(ids, with:)
    bulk_load_and_compute([*Array(with), :id], ids: ids)
  end

  define_primary_loader :raw_user do |subfields, ids:, **|
    RawUser.where(id: ids).select(subfields).map { new(_1) }
  end

  delegate_dependency :id, :first_name, :last_name,
    to: :raw_user, include_subfields: true

  dependency :first_name, :last_name
  computed def full_name
    [first_name, last_name].compact.join(' ')
  end
end
```

```ruby
class UserPbSerializer < Pb::Serializer::Base
  message ExamplesPb::User

  attribute :id
  attribute :first_name
  attribute :last_name
  attribute :full_name
end
```

```ruby
# req.read_mask # => <Google::Protobuf::FieldMask: paths: ['id', 'full_name']>
mask = Pb::Serializer.parse_field_mask(req.read_mask)

user = User.batch_get([123], with: mask)[0]
UserPbSerializer.new(user).to_pb(with: mask)
# => <ExamplesPb::User: id: 123, first_name: '', last_name: '', full_name: "Masayuki Izumi">
```
