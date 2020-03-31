RSpec.describe 'has_many_through associaitons' do
  include DBHelper

  shared_context 'serializes successfully' do
    setup_db do
      create_table :posts do |t|
        t.string :title
        t.string :body
      end
      create_table :tags do |t|
        t.string :name
      end
      create_table :post_taggings do |t|
        t.belongs_to :post
        t.belongs_to :tag
      end
    end

    let(:sandbox) { self.class::Sandbox }

    module self::Sandbox
      class Post < ActiveRecord::Base
        has_many :post_taggings
        has_many :tags, through: :post_taggings
      end
      class Tag < ActiveRecord::Base; end
      class PostTagging < ActiveRecord::Base
        belongs_to :post
        belongs_to :tag
      end
      class TagSerializer < Pb::Serializer::Base
        message TestFixture::HasManyThrough::Tag

        attribute :name
      end
      class PostSerializer < Pb::Serializer::Base
        message TestFixture::HasManyThrough::Post

        define_primary_loader :post do |subdeps, ids:, **|
          Post.where(id: ids).preload(subdeps).map { |p| new(p) }
        end

        attribute :id
        attribute :title
        attribute :body
      end
    end

    let!(:posts) do
      [
        sandbox::Post.create(title: "Post 1", body: "Hello World!").tap do |p|
          p.tags << sandbox::Tag.find_or_create_by!(name: "Tag 1")
          p.tags << sandbox::Tag.find_or_create_by!(name: "Tag 2")
        end,
        sandbox::Post.create(title: "Post 2", body: "Hello World!!").tap do |p|
          p.tags << sandbox::Tag.find_or_create_by!(name: "Tag 3")
          p.tags << sandbox::Tag.find_or_create_by!(name: "Tag 4")
          p.tags << sandbox::Tag.find_or_create_by!(name: "Tag 1")
        end,
      ]
    end

    execute_and_record_queries do
      sandbox::PostSerializer.bulk_load_and_serialize(ids: posts.map(&:id))
    end

    it { expect(result.size).to eq 2 }
    it { expect(result[0].title).to eq 'Post 1' }
    it { expect(result[0].tags.size).to eq 2 }
    it { expect(result[0].tags[0].name).to eq 'Tag 1' }
    it { expect(result[0].tags[1].name).to eq 'Tag 2' }
    it { expect(result[1].tags.size).to eq 3 }
    it 'preloads sub-dependencies' do
      expect(queries.size).to eq 3
    end
  end

  context 'load tags as sub-dependencies' do
    include_context 'serializes successfully'

    module self::Sandbox
      class PostSerializer < Pb::Serializer::Base
        attribute :tags, serializer: TagSerializer
        delegate_dependency :tags, to: :post, include_subdeps: true
      end
    end
  end

  context 'load tags with user-defined loader' do
    include_context 'serializes successfully'

    module self::Sandbox
      class TagSerializer < Pb::Serializer::Base
        define_primary_loader :tag do |subdeps, ids:, **|
          Tag.where(id: ids).preload(subdeps).map { |p| new(p) }
        end
      end
      class PostSerializer < Pb::Serializer::Base
        attribute :tags

        define_loader :tags, key: -> { id } do |post_ids, subdeps, **|
          taggings = PostTagging.where(post_id: post_ids).pluck(:tag_id, :post_id).each_with_object({}) { |(t_id, p_id) ,h| (h[p_id] ||= []) << t_id }
          tags = TagSerializer.bulk_load(with: subdeps, ids: taggings.values.flatten).index_by { |s| s.tag.id }
          taggings.transform_values { |t_ids| t_ids.map { |id| tags[id] } }
        end
      end
    end
  end
end
