module DBHelper
  def self.included(base)
    require "active_record"

    base.extend ClassMethods
  end

  module ClassMethods
    def setup_db(verbose: false, &block)
      klass = Class.new(ActiveRecord::Migration[6.0])
      klass.define_method :change, &block
      klass.verbose = verbose

      around(:each) do |e|
        ActiveRecord::Base.establish_connection(
          adapter: "sqlite3",
          database: ":memory:",
        )
        klass.migrate :up
        e.run
        klass.migrate :down
        ActiveRecord::Base.remove_connection
      end
    end

    def execute_and_record_queries(&block)
      let(:result_and_queries) do
        resp = nil
        queries = []

        ActiveSupport::Notifications.subscribed(
          -> (_, _, _, _, args) { queries << { name: args[:name], sql: args[:sql] } },
          'sql.active_record',
        ) do
          resp = instance_eval(&block)
        end

        [resp, queries]
      end

      let(:result) { result_and_queries[0] }
      let(:queries) { result_and_queries[1] }
    end
  end
end
