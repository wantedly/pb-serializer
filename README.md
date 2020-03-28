# Pb::Serializer

```rb
class UserSerializer < Pb::Serializer::Base
  message YourApp::User

  attribute :id,    required: true
  attribute :name,  required: true
  attribute :posts, required: true

  define_primary_loader :user do |subdeps, ids:, **|
    User.where(id: ids).preload(subdeps).map { |u| new(u) }
  end

  define_loader :posts, key: -> { id } do |user_ids, subdeps, **|
    PostSerializer.bulk_load(user_id: user_ids, with: subdeps).group_by { |s| s.post.user_id }
  end

  dependency :posts
  computed def post_count
    posts.count
  end
end

class PostSerializer < Pb::Serializer::Base
  message YourApp::Post

  define_primary_loader :post do |subdeps, user_ids:, **|
    Post.where(user_id: user_ids).preload(subdeps).map { |p| new(p) }
  end

  attribute :id,    required: true
  attribute :title, required: true
  attribute :body,  required: true
end

class UserGrpcService < YourApp::UserService::Service
  # @param req [YourApp::GetUserRequest]
  # @param call [GRPC::ActiveCall::SingleReqView]
  # @return [YourApp::User]
  def get_users(req, call)
    UserSerializer.bulk_load_and_serialize(ids: [req.user_id], with: req.field_mask)[0]
  end

  # @param req [YourApp::ListFriendUsersRequest]
  # @param call [GRPC::ActiveCall::SingleReqView]
  # @return [YourApp::ListFriendUsersResponse]
  def list_friend_users(req, call)
    current_user = User.find(current_user_id)
    YourApp::ListFriendUsersResponse.new(
      users: UserSerializer.bulk_load_and_serialize(ids: current_user.friend_ids, with: req.field_mask)
    )
  end
end
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pb-serializer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pb-serializer

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/izumin5210/pb-serializer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pb::Serializer project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/izumin5210/pb-serializer/blob/master/CODE_OF_CONDUCT.md).
