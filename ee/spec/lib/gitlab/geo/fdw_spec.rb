require 'spec_helper'

describe Gitlab::Geo::Fdw, :geo do
  describe '.enabled?' do
    it 'returns false when foreign server does not exist' do
      drop_foreign_server

      expect(described_class.enabled?).to eq false
    end

    it 'returns false when foreign server exists but foreign schema does not exist' do
      drop_foreign_schema

      expect(described_class.enabled?).to eq false
    end

    it 'returns false when foreign server and schema exists but foreign tables are empty' do
      drop_foreign_schema
      create_foreign_schema

      expect(described_class.enabled?).to eq false
    end

    it 'returns false when fdw is disabled in `config/database_geo.yml`' do
      allow(Rails.configuration).to receive(:geo_database).and_return('fdw' => false)

      expect(described_class.enabled?).to be_falsey
    end

    it 'returns true when fdw is set in `config/database_geo.yml`' do
      allow(Rails.configuration).to receive(:geo_database).and_return('fdw' => true)

      expect(described_class.enabled?).to be_truthy
    end

    it 'returns true when fdw is nil in `config/database_geo.yml`' do
      allow(Rails.configuration).to receive(:geo_database).and_return('fdw' => nil)

      expect(described_class.enabled?).to be_truthy
    end

    it 'returns true with a functional fdw environment' do
      expect(described_class.enabled?).to be_truthy
    end
  end

  describe '.enabled_for_selective_sync?' do
    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(use_fdw_queries_for_selective_sync: true)
      end

      it 'returns false when FDW is disabled' do
        allow(described_class).to receive(:enabled?).and_return(false)

        expect(described_class.enabled_for_selective_sync?).to eq false
      end

      it 'returns true when FDW is enabled' do
        expect(described_class.enabled_for_selective_sync?).to eq true
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(use_fdw_queries_for_selective_sync: false)
      end

      it 'returns false when FDW is disabled' do
        allow(described_class).to receive(:enabled?).and_return(false)

        expect(described_class.enabled_for_selective_sync?).to eq false
      end

      it 'returns false when FDW is enabled' do
        expect(described_class.enabled_for_selective_sync?).to eq false
      end
    end
  end

  describe '.foreign_tables_up_to_date?' do
    it 'returns false when foreign schema does not exist' do
      drop_foreign_schema

      expect(described_class.foreign_tables_up_to_date?).to eq false
    end

    it 'returns false when foreign schema exists but tables in schema doesnt match' do
      create_foreign_table(:gitlab_test)

      expect(described_class.foreign_tables_up_to_date?).to eq false
    end

    it 'returns true when foreign schema exists and foreign schema has same tables as secondary database' do
      expect(described_class.foreign_tables_up_to_date?).to eq true
    end
  end

  describe '.foreign_schema_tables_count' do
    before do
      drop_foreign_schema
      create_foreign_schema
    end

    it 'returns the number of tables in the foreign schema' do
      create_foreign_table(:gitlab_test)

      expect(described_class.foreign_schema_tables_count).to eq(1)
    end

    it 'excludes tables that start with `pg_`' do
      create_foreign_table(:pg_gitlab_test)

      expect(described_class.foreign_schema_tables_count).to eq(0)
    end
  end

  describe '.gitlab_schema_tables_count' do
    it 'returns the same number of tables as defined in the database' do
      expect(described_class.gitlab_schema_tables_count).to eq(ActiveRecord::Schema.tables.count)
    end

    it 'excludes tables that start with `pg_`' do
      ActiveRecord::Base.connection.create_table(:pg_gitlab_test)

      expect(described_class.gitlab_schema_tables_count).to eq(ActiveRecord::Schema.tables.count - 1)

      ActiveRecord::Base.connection.drop_table(:pg_gitlab_test)
    end
  end

  def with_foreign_connection
    Geo::TrackingBase.connection
  end

  def drop_foreign_server
    with_foreign_connection.execute <<-SQL
      DROP SERVER IF EXISTS #{described_class::FOREIGN_SERVER} CASCADE
    SQL
  end

  def drop_foreign_schema
    with_foreign_connection.execute <<-SQL
      DROP SCHEMA IF EXISTS #{described_class::FOREIGN_SCHEMA} CASCADE
    SQL
  end

  def create_foreign_schema
    with_foreign_connection.execute <<-SQL
      CREATE SCHEMA IF NOT EXISTS #{described_class::FOREIGN_SCHEMA}
    SQL

    with_foreign_connection.execute <<-SQL
      GRANT USAGE ON FOREIGN SERVER #{described_class::FOREIGN_SERVER} TO current_user
    SQL
  end

  def create_foreign_table(table_name)
    with_foreign_connection.execute <<-SQL
      CREATE FOREIGN TABLE IF NOT EXISTS #{described_class::FOREIGN_SCHEMA}.#{table_name} (
        id int
      ) SERVER #{described_class::FOREIGN_SERVER}
    SQL
  end
end
