require "active_record"

RSpec.describe Pb::Serializer do
  module self::Sandbox
    class User < ActiveRecord::Base
      has_one :profile
      has_one :preference
      has_one :github_account
      has_one :twitter_account
    end

    class ProfileSkill < ActiveRecord::Base
      belongs_to :skill
      belongs_to :profile
    end

    class Skill < ActiveRecord::Base
    end

    class Profile < ActiveRecord::Base
      belongs_to :user
      has_many :works
      has_many :profile_skills
      has_many :skills, through: :profile_skills
    end

    class Company < ActiveRecord::Base
    end

    class Work < ActiveRecord::Base
      belongs_to :proflie
      belongs_to :company
    end

    class Preference < ActiveRecord::Base
      belongs_to :user
    end

    class GithubAccount < ActiveRecord::Base
      belongs_to :user
    end

    class TwitterAccount < ActiveRecord::Base
      belongs_to :user
    end

    class DateSerializer < Pb::Serializer::Base
      message TestFixture::Date

      attribute :year,  required: true
      attribute :month, required: true
      attribute :day,   required: true
    end

    class CompanySerializer < Pb::Serializer::Base
      message TestFixture::Company

      attribute :name,           required: true
      attribute :logo_image_url, required: true
    end

    class WorkSerializer < Pb::Serializer::Base
      message TestFixture::Work

      attribute :company,  required: true, serializer: CompanySerializer
      attribute :position, required: true

      delegate_dependency :company, to: :work, include_subdeps: true

      define_primary_loader :work do |subdeps, profile_ids:, **|
        Work.where(profile_id: profile_ids).preload(subdeps).map { |w| new(w) }
      end
    end

    class PreferenceSerializer < Pb::Serializer::Base
      message TestFixture::Preference

      attribute :email, required: true
    end

    class GithubAccountSerializer < Pb::Serializer::Base
      message TestFixture::GithubAccount

      attribute :login, required: true
    end

    class TwitterAccountSerializer < Pb::Serializer::Base
      message TestFixture::TwitterAccount

      attribute :login, required: true
    end

    class AccountSerializer < Pb::Serializer::Base
      message TestFixture::Account

      oneof :account, required: true do
        attribute :github,  serializer: GithubAccountSerializer
        attribute :twitter, serializer: TwitterAccountSerializer
      end
    end

    class UserSerializer < Pb::Serializer::Base
      message TestFixture::User

      attribute :id,            required: true
      attribute :registered_at, required: true
      attribute :name,          required: true
      attribute :avatar_url
      attribute :birthday,      serializer: DateSerializer
      attribute :age

      attribute :skills
      attribute :works,      required: true
      attribute :preference, required: true, serializer: PreferenceSerializer
      attribute :accounts,   required: true, serializer: AccountSerializer

      delegate_dependency :name,       to: :profile
      delegate_dependency :avatar_url, to: :profile
      delegate_dependency :birthday,   to: :profile

      delegate_dependency :github_account,  to: :user,                include_subdeps: true
      delegate_dependency :twitter_account, to: :user,                include_subdeps: true
      delegate_dependency :preference,      to: :user,                include_subdeps: true
      delegate_dependency :skills,          to: :profile, prefix: :_, include_subdeps: true

      define_primary_loader :user do |subdeps, ids:, **|
        User.where(id: ids).preload(subdeps).map { |u| new(u) }
      end

      define_loader :profile, key: -> { id } do |keys, subdeps, **|
        Profile.where(user_id: keys).preload(subdeps).index_by(&:user_id)
      end

      define_loader :works, key: -> { profile.id } do |keys, subdeps, **|
        WorkSerializer.bulk_load(with: subdeps, profile_ids: keys).group_by { |s| s.work.profile_id }
      end

      dependency :profile
      computed def age
        return nil if birthday.nil?
        [Date.today, birthday].map {|d| d.strftime("%Y%m%d").to_i }.yield_self {|(t, b)| t - b } / 10000
      end

      dependency :profile
      computed def avatar_url
        profile.avatar_url || "http://example.com/default_avatar.png"
      end

      dependency :profile
      computed def original_avatar_url
        profile.avatar_url
      end

      Account = Struct.new(:twitter, :github, keyword_init: true)

      dependency :github_account, :twitter_account
      computed def accounts
        accs = []
        accs << Account.new(github: github_account) if github_account
        accs << Account.new(twitter: twitter_account) if twitter_account
        accs
      end

      dependency :__skills
      computed def skills
        __skills.map(&:name)
      end
    end
  end

  let(:sandbox) { self.class::Sandbox }

  before do
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: ":memory:",
    )
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.create_table :users do |t|
      t.datetime :registered_at
    end
    m.create_table :preferences do |t|
      t.belongs_to :user
      t.string :email
    end
    m.create_table :profiles do |t|
      t.belongs_to :user
      t.string :name
      t.string :avatar_url
      t.date :birthday
    end
    m.create_table :companies do |t|
      t.string :name, null: false
      t.string :logo_image_url, null: false
    end
    m.create_table :works do |t|
      t.belongs_to :profile
      t.belongs_to :company
      t.string :position
    end
    m.create_table :github_accounts do |t|
      t.belongs_to :user
      t.string :login
    end
    m.create_table :twitter_accounts do |t|
      t.belongs_to :user
      t.string :login
    end
    m.create_table :skills do |t|
      t.string :name, null: false
    end
    m.create_table :profile_skills do |t|
      t.belongs_to :profile
      t.belongs_to :skill
    end
  end

  after do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.drop_table :profile_skills
    m.drop_table :skills
    m.drop_table :twitter_accounts
    m.drop_table :github_accounts
    m.drop_table :preferences
    m.drop_table :works
    m.drop_table :companies
    m.drop_table :profiles
    m.drop_table :users
  end

  it "has a version number" do
    expect(Pb::Serializer::VERSION).not_to be nil
  end

  let(:company1) { sandbox::Company.create(name: "Foo, inc.", logo_image_url: 'https://example.com/companies/foo/logo') }
  let(:company2) { sandbox::Company.create(name: "Bar LLC", logo_image_url: 'https://example.com/companies/bar/logo') }

  let(:user1) do
    sandbox::User.create(registered_at: Time.now).tap do |user|
      profile = user.create_profile!(
        name: "Test User1",
        avatar_url: "https://example.com/testuser1/avatar",
        birthday: Date.new(1992, 1, 20),
      )
      user.create_preference!(
        email: 'testuser1@example.com'
      )
      profile.skills << sandbox::Skill.find_or_create_by!(name: "Ruby")
      profile.skills << sandbox::Skill.find_or_create_by!(name: "TypeScript")
      profile.skills << sandbox::Skill.find_or_create_by!(name: "React.js")
      user.create_twitter_account!(login: 'testuser1')
      user.create_github_account!(login: 'testuser1')
      profile.works.create!(company: company1, position: 'Software Engineer')
      profile.works.create!(company: company2, position: 'Software Engineer')
      profile.works.create!(company: company2, position: 'Senior Software Engineer')
    end
  end

  let(:user2) do
    sandbox::User.create(registered_at: Time.now).tap do |user|
      profile = user.create_profile!(
        name: "Test User2",
        avatar_url: "https://example.com/testuser2/avatar",
        birthday: Date.new(1990, 9, 14),
      )
      user.create_preference!(
        email: 'testuser2@example.com'
      )
      user.create_twitter_account!(login: 'testuser2')
      profile.skills << sandbox::Skill.find_or_create_by!(name: "Rust")
      profile.skills << sandbox::Skill.find_or_create_by!(name: "C++")
      profile.works.create!(company: company1, position: 'Senior Software Engineer')
    end
  end

  describe ".serialize" do
    it "serializes ruby object into protobuf message" do
      ids = [user1.id, user2.id]
      pbs = nil
      query_names = []

      ActiveSupport::Notifications.subscribed(-> (_, _, _, _, sql:, name:, **args) { query_names << name }, 'sql.active_record') do
        pbs = sandbox::UserSerializer.bulk_load_and_serialize(ids: ids)
      end

      load_queries = query_names.select { |n| n.end_with?(' Load') }
      expect(load_queries.size).to eq 9
      expect(load_queries.each_with_object(Hash.new(0)) { |n, h| h[n] += 1 }.values).to all(eq 1)

      pb = pbs[0]
      expect(pb).to be_kind_of TestFixture::User
      expect(pb.name).to eq user1.profile.name
      expect(pb.registered_at).to be_kind_of Google::Protobuf::Timestamp
      expect(pb.registered_at.seconds).to eq user1.registered_at.to_i
      expect(pb.avatar_url).to be_kind_of Google::Protobuf::StringValue
      expect(pb.avatar_url.value).to eq user1.profile.avatar_url
      expect(pb.birthday).to be_kind_of TestFixture::Date
      expect(pb.birthday.year).to eq 1992
      expect(pb.birthday.month).to eq 1
      expect(pb.birthday.day).to eq 20
      expect(pb.skills).to match ['Ruby', 'TypeScript', 'React.js']
      expect(pb.works.size).to eq 3
      expect(pb.works[0].company.name).to eq 'Foo, inc.'
      expect(pb.works[0].position).to eq 'Software Engineer'
      expect(pb.works[1].company.name).to eq 'Bar LLC'
      expect(pb.works[1].position).to eq 'Software Engineer'
      expect(pb.works[2].company.name).to eq 'Bar LLC'
      expect(pb.works[2].position).to eq 'Senior Software Engineer'
      expect(pb.accounts.size).to eq 2
      expect(pb.accounts[0].twitter&.login).to be_nil
      expect(pb.accounts[0].github&.login).to eq 'testuser1'
      expect(pb.accounts[1].twitter&.login).to eq 'testuser1'
      expect(pb.accounts[1].github&.login).to be_nil
    end

    it "raises a validation error when required attriutes are blank" do
      user = sandbox::User.create(registered_at: Time.now)
      user.create_profile!

      expect { sandbox::UserSerializer.bulk_load_and_serialize(ids: [user.id]) }.to raise_error ::Pb::Serializer::ValidationError
    end

    it "raises a validation error when required oneof attributes are blank" do
      account = Struct.new(:twitter, :github).new(nil, nil)

      expect { sandbox::AccountSerializer.new(account).to_pb }.to raise_error ::Pb::Serializer::ValidationError
    end

    it "raises a conflict error when oneof attributes set twice" do
      account = Struct.new(:twitter, :github).new(
        sandbox::TwitterAccount.new(login: 'izumin5210'),
        sandbox::TwitterAccount.new(login: 'izumin5210'),
      )

      expect { sandbox::AccountSerializer.new(account).to_pb }.to raise_error ::Pb::Serializer::ConflictOneofError
    end
  end
end
