RSpec.describe 'oneof field' do
  include DBHelper

  setup_db do
    create_table :users do |t|
      t.string :name
    end
    create_table :github_accounts do |t|
      t.belongs_to :user
      t.string :login
    end
    create_table :twitter_accounts do |t|
      t.belongs_to :user
      t.string :login
    end
  end

  module self::Sandbox
    class User < ActiveRecord::Base
      has_many :github_accounts
      has_many :twitter_accounts
    end
    class GithubAccount < ActiveRecord::Base; end
    class TwitterAccount < ActiveRecord::Base; end
    class GithubAccountSerializer < Pb::Serializer::Base
      message TestFixture::Oneof::GithubAccount
      attribute :login
    end
    class TwitterAccountSerializer < Pb::Serializer::Base
      message TestFixture::Oneof::TwitterAccount

      attribute :login
    end
    class AccountSerializer < Pb::Serializer::Base
      message TestFixture::Oneof::Account

      oneof :account do
        attribute :github,  serializer: GithubAccountSerializer
        attribute :twitter, serializer: TwitterAccountSerializer
      end
    end
    class UserSerializer < Pb::Serializer::Base
      message TestFixture::Oneof::User

      attribute :name
      attribute :accounts, serializer: AccountSerializer

      delegate_dependency :github_accounts,  to: :user, include_subfields: true
      delegate_dependency :twitter_accounts, to: :user, include_subfields: true

      define_primary_loader :user do |subdeps, ids:, **|
        User.where(id: ids).preload(subdeps).map { |u| new(u) }
      end

      Account = Struct.new(:twitter, :github, keyword_init: true)

      dependency :github_accounts, :twitter_accounts
      computed def accounts
        [
          *github_accounts.map { |github| Account.new(github: github) },
          *twitter_accounts.map { |twitter| Account.new(twitter: twitter) },
        ]
      end
    end
  end

  let(:sandbox) { self.class::Sandbox }

  let!(:users) do
    [
      sandbox::User.create!(name: "Test User1").tap do |u|
        u.github_accounts.create!(login: "testuser1")
      end,
      sandbox::User.create!(name: "Test User2").tap do |u|
        u.github_accounts.create!(login: "testuser2")
        u.twitter_accounts.create!(login: "testuser2")
        u.twitter_accounts.create!(login: "testuser2_sub")
      end,
    ]
  end

  execute_and_record_queries do
    sandbox::UserSerializer.bulk_load_and_serialize(ids: users.map(&:id))
  end

  it { expect(result.size).to eq 2 }
  it { expect(result[0].name).to eq 'Test User1' }
  it { expect(result[0].accounts.size).to eq 1 }
  it { expect(result[0].accounts[0].github.login).to eq 'testuser1' }
  it { expect(result[1].name).to eq 'Test User2' }
  it { expect(result[1].accounts.size).to eq 3 }
  it { expect(result[1].accounts[0].github.login).to eq 'testuser2' }
  it { expect(result[1].accounts[1].twitter.login).to eq 'testuser2' }
  it { expect(result[1].accounts[2].twitter.login).to eq 'testuser2_sub' }
  it 'preloads sub-dependencies' do
    expect(queries.size).to eq 3
  end

  it "raises a validation error when required oneof attributes are blank" do
    account = Struct.new(:twitter, :github).new(nil, nil)

    expect { sandbox::AccountSerializer.new(account).to_pb }.to raise_error ::Pb::Serializer::ValidationError
  end

  it "raises a conflict error when oneof attributes set twice" do
    account = Struct.new(:twitter, :github).new(
      sandbox::TwitterAccount.new(login: 'testuser'),
      sandbox::GithubAccount.new(login: 'testuser'),
    )

    expect { sandbox::AccountSerializer.new(account).to_pb }.to raise_error ::Pb::Serializer::ConflictOneofError
  end
end
