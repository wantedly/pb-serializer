RSpec.describe 'has_many association' do
  include DBHelper

  shared_context 'serializes successfully' do
    setup_db do
      create_table :users do |t|
        t.string :name
      end
      create_table :posts do |t|
        t.belongs_to :user
        t.string :title
        t.string :body
      end
    end

    module self::Sandbox
      class User < ActiveRecord::Base
        has_many :posts
      end
      class Post < ActiveRecord::Base; end
      class UserSerializer < Pb::Serializer::Base
        message TestFixture::HasMany::User

        attribute :id
        attribute :name
        attribute :posts

        define_primary_loader :user do |subdeps, ids:, **|
          User.where(id: ids).preload(subdeps).map { |u| new(u) }
        end
      end
      class PostSerializer < Pb::Serializer::Base
        message TestFixture::HasMany::Post

        attribute :id
        attribute :title
        attribute :body
      end
    end

    let(:sandbox) { self.class::Sandbox }
    let!(:users) do
      [
        sandbox::User.create(name: "Test User1").tap do |u|
          u.posts.create(title: "Post 1", body: "hello world!")
          u.posts.create(title: "Post 2", body: "hello world!!")
        end,
        sandbox::User.create(name: "Test User2").tap do |u|
          u.posts.create(title: "Post 3", body: "hello world!!!")
          u.posts.create(title: "Post 4", body: "hello world!!!!")
          u.posts.create(title: "Post 5", body: "hello world!!!!!")
        end,
      ]
    end

    execute_and_record_queries do
      sandbox::UserSerializer.bulk_load_and_serialize(ids: users.map(&:id), with: with)
    end
  end

  shared_examples 'fetch all fields' do
    it { expect(result[0].name).to eq 'Test User1' }
    it { expect(result[0].posts.size).to eq 2 }
    it { expect(result[0].posts[0].title).to eq 'Post 1' }
    it 'preloads sub-dependencies' do
      expect(queries.select { |args| args[:name].end_with?(' Load') }.size).to eq 2
    end
  end

  context 'load posts as sub-dependencies' do
    include_context 'serializes successfully'
    it_behaves_like 'fetch all fields'

    let(:with) { nil }

    context 'when a required field is null' do
      before { users[0].posts.create(title: 'Post invalid') }
      it { expect { result }.to raise_error ::Pb::Serializer::ValidationError }
    end

    context 'when load only 1 field' do
      let(:with) { [:name] }
      it { expect(result[0].name).to eq 'Test User1' }
      it { expect(result[0].posts.size).to eq 0 }
      it 'loads only users table' do
        expect(queries.size).to eq 1
        expect(queries.select  { |args| args[:name].end_with?('User Load') }.size).to eq 1
      end
    end

    context 'when load nested fields' do
      let(:with) { Google::Protobuf::FieldMask.new(paths: ["name","posts.id", "posts.title"]) }
      it { expect(result[0].name).to eq 'Test User1' }
      it { expect(result[0].posts.size).to eq 2 }
      it { expect(result[0].posts[0].title).to eq 'Post 1' }
      it { expect(result[0].posts[1].title).to eq 'Post 2' }
      it { expect(result[0].posts[0].body).to be_empty }
    end

    module self::Sandbox
      class UserSerializer < Pb::Serializer::Base
        attribute :posts, serializer: PostSerializer
        delegate_dependency :posts, to: :user, include_subfields: true
      end
    end
  end

  context 'load posts with user-defined loader' do
    include_context 'serializes successfully'
    it_behaves_like 'fetch all fields'

    let(:with) { nil }

    context 'when a required field is null' do
      before { users[0].posts.create(title: 'Post invalid') }
      it { expect { result }.to raise_error ::Pb::Serializer::ValidationError }
    end

    module self::Sandbox
      class UserSerializer < Pb::Serializer::Base
        dependency :user
        define_loader :posts, key: -> { id } do |user_ids, subdeps, **|
          PostSerializer.bulk_load(user_ids: user_ids, with: subdeps).group_by { |s| s.post.user_id }
        end
      end
      class PostSerializer < Pb::Serializer::Base
        define_primary_loader :post do |subdeps, user_ids:, **|
          Post.where(user_id: user_ids).preload(subdeps).map { |p| new(p) }
        end
      end
    end
  end
end
