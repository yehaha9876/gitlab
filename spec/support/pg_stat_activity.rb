# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    if Gitlab::Database.postgresql?
      results = ActiveRecord::Base.connection.execute('SELECT * FROM pg_stat_activity')

      warn('*' * 20 + "pg_stat_activity (#{results.ntuples})" + '*' * 20)

      if results.ntuples > 50
        results.each do |result|
          warn result.inspect
        end
      end
    end
  end
end
