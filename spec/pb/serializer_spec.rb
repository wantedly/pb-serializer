require "active_record"

RSpec.describe Pb::Serializer do
  module self::Sandbox
    class User < ActiveRecord::Base
      has_one :profile
      has_one :preference
      has_one :github_account
      has_one :twitter_account
    end

    class Profile < ActiveRecord::Base
      belongs_to :user
      has_many :works

      serialize :skills, Array
    end

    class Work < ActiveRecord::Base
      belongs_to :proflie
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

    class WorkSerializer < Pb::Serializer::Base
      message TestFixture::Work

      attribute :company, required: true
      attribute :position, required: true
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

      attribute :works,      required: true, serializer: WorkSerializer
      attribute :preference, required: true, serializer: PreferenceSerializer
      attribute :accounts,   required: true, serializer: AccountSerializer

      delegate_dependency :name,       to: :profile
      delegate_dependency :avatar_url, to: :profile
      delegate_dependency :birthday,   to: :profile
      delegate_dependency :skills,     to: :profile
      delegate_dependency :works,      to: :profile, include_subdeps: true

      define_loader :profile do |users, subdeps, **|
        profiles = Profile.where(user_id: users.map(&:id)).preload(subdeps).index_by(&:user_id)
        users.each do |user|
          user.profile = profiles[user.id]
        end
      end

      define_loader :preference do |users, _subdeps, **|
        preferences = Preference.where(user_id: users.map(&:id)).index_by(&:user_id)
        users.each do |user|
          user.preference = preferences[user.id]
        end
      end

      define_loader :github_account do |users, _subdeps, **|
        accs = GithubAccount.where(user_id: users.map(&:id)).index_by(&:user_id)
        users.each do |user|
          user.github_account = accs[user.id]
        end
      end

      define_loader :twitter_account do |users, _subdeps, **|
        accs = TwitterAccount.where(user_id: users.map(&:id)).index_by(&:user_id)
        users.each do |user|
          user.twitter_account = accs[user.id]
        end
      end

      dependency :profile
      computed def age
        return nil if object&.profile&.birthday.nil?
        [Date.today, object.profile.birthday].map {|d| d.strftime("%Y%m%d").to_i }.yield_self {|(t, b)| t - b } / 10000
      end

      dependency :profile
      computed def avatar_url
        object.profile.avatar_url || "http://example.com/default_avatar.png"
      end

      dependency :profile
      computed def original_avatar_url
        object.profile.avatar_url
      end

      Account = Struct.new(:twitter, :github, keyword_init: true)

      dependency :github_account, :twitter_account
      computed def accounts
        accs = []
        accs << Account.new(github: github_account) if github_account
        accs << Account.new(twitter: twitter_account) if twitter_account
        accs
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
      t.string :skills#, array: true # NOTE: sqlite3 does not support array columns
    end
    m.create_table :works do |t|
      t.belongs_to :profile
      t.string :company
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
  end

  after do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.drop_table :twitter_accounts
    m.drop_table :github_accounts
    m.drop_table :preferences
    m.drop_table :works
    m.drop_table :profiles
    m.drop_table :users
  end

  it "has a version number" do
    expect(Pb::Serializer::VERSION).not_to be nil
  end

  describe ".serialize" do
    it "serializes ruby object into protobuf message" do
      user = sandbox::User.create(registered_at: Time.now)
      profile = user.create_profile!(
        name: "Masayuki Izumi",
        avatar_url: "https://example.com/izumin5210/avatar",
        birthday: Date.new(1993, 2, 10),
        skills: ['Ruby', 'Go', 'TypeScript', 'React.js'],
      )
      user.create_preference!(
        email: 'izumin5210@example.com'
      )
      user.create_twitter_account!(login: 'izumin5210')
      user.create_github_account!(login: 'izumin5210')
      profile.works.create!(company: "Foo, inc.", position: 'Software Engineer')
      profile.works.create!(company: "Bar LLC", position: 'Software Engineer')
      profile.works.create!(company: "Bar LLC", position: 'Senior Software Engineer')
      pb = sandbox::UserSerializer.serialize(user)
      expect(pb).to be_kind_of TestFixture::User
      expect(pb.name).to eq profile.name
      expect(pb.registered_at).to be_kind_of Google::Protobuf::Timestamp
      expect(pb.registered_at.seconds).to eq user.registered_at.to_i
      expect(pb.avatar_url).to be_kind_of Google::Protobuf::StringValue
      expect(pb.avatar_url.value).to eq profile.avatar_url
      expect(pb.birthday).to be_kind_of TestFixture::Date
      expect(pb.birthday.year).to eq 1993
      expect(pb.birthday.month).to eq 2
      expect(pb.birthday.day).to eq 10
      expect(pb.skills).to match ['Ruby', 'Go', 'TypeScript', 'React.js']
      expect(pb.works.size).to eq 3
      expect(pb.works[0].company).to eq 'Foo, inc.'
      expect(pb.works[0].position).to eq 'Software Engineer'
      expect(pb.works[1].company).to eq 'Bar LLC'
      expect(pb.works[1].position).to eq 'Software Engineer'
      expect(pb.works[2].company).to eq 'Bar LLC'
      expect(pb.works[2].position).to eq 'Senior Software Engineer'
      expect(pb.accounts.size).to eq 2
      expect(pb.accounts[0].twitter&.login).to be_nil
      expect(pb.accounts[0].github&.login).to eq 'izumin5210'
      expect(pb.accounts[1].twitter&.login).to eq 'izumin5210'
      expect(pb.accounts[1].github&.login).to be_nil
    end

    it "raises a validation error when required attriutes are blank" do
      user = sandbox::User.create(registered_at: Time.now)
      user.create_profile!

      expect { sandbox::UserSerializer.serialize(user) }.to raise_error ::Pb::Serializer::ValidationError
    end
  end
end
