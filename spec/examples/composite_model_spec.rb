RSpec.describe 'composite AR models into 1 message' do
  include DBHelper

  setup_db do
    create_table :users do |t|
      t.string :login
    end
    create_table :profiles do |t|
      t.belongs_to :user
      t.string :name
      t.string :avatar_url
      t.date :birthday
    end
    create_table :skills do |t|
      t.string :name, null: false
    end
    create_table :profile_skills do |t|
      t.belongs_to :profile
      t.belongs_to :skill
    end
  end

  module self::Sandbox
    TODAY = Date.new(2020, 03, 29)

    class User < ActiveRecord::Base
      has_one :profile
    end

    class ProfileSkill < ActiveRecord::Base
      belongs_to :skill
      belongs_to :profile
    end

    class Skill < ActiveRecord::Base; end

    class Profile < ActiveRecord::Base
      has_many :profile_skills
      has_many :skills, through: :profile_skills
    end

    class DateSerializer < Pb::Serializer::Base
      message TestFixture::CompositeModel::Date

      attribute :year
      attribute :month
      attribute :day
    end

    class UserSerializer < Pb::Serializer::Base
      message TestFixture::CompositeModel::User

      attribute :id
      attribute :login
      attribute :display_name
      attribute :avatar_url
      attribute :birthday, serializer: DateSerializer
      attribute :age
      attribute :skills

      delegate_dependency :avatar_url, to: :profile
      delegate_dependency :birthday,   to: :profile
      delegate_dependency :skills,     to: :profile, prefix: :_, include_subfields: true

      define_primary_loader :user do |subdeps, ids:, **|
        User.where(id: ids).preload(subdeps).map { |u| new(u) }
      end

      dependency :user
      define_loader :profile, key: -> { id } do |keys, subdeps, **|
        Profile.where(user_id: keys).preload(subdeps).index_by(&:user_id)
      end

      dependency :profile
      computed def display_name
        profile.name
      end

      dependency :profile, :birthday
      computed def age
        return nil if birthday.nil?
        [TODAY, birthday].map {|d| d.strftime("%Y%m%d").to_i }.yield_self {|(t, b)| t - b } / 10000
      end

      dependency :__skills
      computed def skills
        __skills.map(&:name)
      end
    end
  end

  let(:sandbox) { self.class::Sandbox }

  let!(:user1) do
    sandbox::User.create(login: 'testuser1').tap do |user|
      profile = user.create_profile!(
        name: "Test User1",
        avatar_url: "https://example.com/testuser1/avatar",
        birthday: Date.new(1992, 1, 20),
      )
      profile.skills << sandbox::Skill.find_or_create_by!(name: "Ruby")
      profile.skills << sandbox::Skill.find_or_create_by!(name: "TypeScript")
      profile.skills << sandbox::Skill.find_or_create_by!(name: "React.js")
    end
  end

  let!(:user2) do
    sandbox::User.create(login: 'testuser2').tap do |user|
      profile = user.create_profile!(
        name: "Test User2",
        avatar_url: "https://example.com/testuser2/avatar",
        birthday: Date.new(1990, 9, 14),
      )
      profile.skills << sandbox::Skill.find_or_create_by!(name: "Rust")
      profile.skills << sandbox::Skill.find_or_create_by!(name: "C++")
    end
  end

  let(:users) { [user1, user2] }

  execute_and_record_queries do
    sandbox::UserSerializer.bulk_load_and_serialize(ids: users.map(&:id))
  end

  it { expect(result.size).to eq 2 }
  it { expect(result[0].login).to eq 'testuser1' }
  it { expect(result[0].display_name).to eq 'Test User1' }
  it { expect(result[0].age).to eq 28 }
  it { expect(result[0].skills).to match %w(Ruby TypeScript React.js) }
  it { expect(result[1].age).to eq 29 }
  it { expect(result[1].skills).to match %w(Rust C++) }
  it 'preloads sub-dependencies' do
    expect(queries.select { |args| args[:name].end_with?(' Load') }.size).to eq 4
  end
end
