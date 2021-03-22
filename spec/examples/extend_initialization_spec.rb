RSpec.describe 'extend initialize method with `define_primary_loader`' do
  include DBHelper

  setup_db do
    create_table :users do |t|
    end

    create_table :user_names do |t|
      t.belongs_to :user
      t.string :name
      t.string :locale
    end
  end

  module self::Sandbox
    class User < ActiveRecord::Base
      has_many :names, class_name: "UserName"
    end

    class UserName < ActiveRecord::Base
      belongs_to :user
    end

    class UserSerializer < Pb::Serializer::Base
      message TestFixture::ExtendInitialization::User

      attribute :name

      delegate_dependency :names, to: :user, prefix: :_, include_subdeps: true

      def initialize(_, locale)
        super
        @locale = locale
      end

      define_primary_loader :user do |subdeps, ids:, locale:|
        User.where(id: ids).preload(subdeps).map { |u| new(u, locale) }
      end

      dependency :__names
      computed def name
        raise "@locale is empty. #initialize is not correctly extended." if @locale.nil?
        __names.find { |n| n.locale == @locale }&.name
      end
    end
  end

  let(:sandbox) { self.class::Sandbox }

  let!(:user1) do
    sandbox::User.create.tap do |user|
      user.names << sandbox::UserName.create(name: "Taro Yamada", locale: "en")
      user.names << sandbox::UserName.create(name: "山田 太郎", locale: "ja")
    end
  end

  let!(:user2) do
    sandbox::User.create.tap do |user|
      user.names << sandbox::UserName.create(name: "Yuki Nakamura", locale: "en")
      user.names << sandbox::UserName.create(name: "中村 由紀", locale: "ja")
    end
  end

  let(:users) { [user1, user2] }

  execute_and_record_queries do
    sandbox::UserSerializer.bulk_load_and_serialize(ids: users.map(&:id), locale: "en")
  end

  it { expect(result.size).to eq 2 }
  it { expect(result[0].name).to eq 'Taro Yamada' }
  it { expect(result[1].name).to eq 'Yuki Nakamura' }

  it 'preloads sub-dependencies' do
    expect(queries.select { |name:, **| name.end_with?(' Load') }.size).to eq 2
  end
end
