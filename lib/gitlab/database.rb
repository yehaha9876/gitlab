module Gitlab
  module Database
    # The max value of INTEGER type is the same between MySQL and PostgreSQL:
    # https://www.postgresql.org/docs/9.2/static/datatype-numeric.html
    # http://dev.mysql.com/doc/refman/5.7/en/integer-types.html
    MAX_INT_VALUE = 2147483647
    # The max value between MySQL's TIMESTAMP and PostgreSQL's timestampz:
    # https://www.postgresql.org/docs/9.1/static/datatype-datetime.html
    # https://dev.mysql.com/doc/refman/5.7/en/datetime.html
    MAX_TIMESTAMP_VALUE = Time.at((1 << 31) - 1).freeze

    def self.config
      ActiveRecord::Base.configurations[Rails.env]
    end

    def self.username
      config['username'] || ENV['USER']
    end

    def self.database_name
      config['database']
    end

    def self.adapter_name
      config['adapter']
    end

    def self.mysql?
      adapter_name.casecmp('mysql2').zero?
    end

    def self.postgresql?
      adapter_name.casecmp('postgresql').zero?
    end

    # Overridden in EE
    def self.read_only?
      Gitlab::Geo.secondary?
    end

    def self.read_write?
      !self.read_only?
    end

    def self.version
      database_version.match(/\A(?:PostgreSQL |)([^\s]+).*\z/)[1]
    end

    def self.join_lateral_supported?
      postgresql? && version.to_f >= 9.3
    end

    def self.nulls_last_order(field, direction = 'ASC')
      order = "#{field} #{direction}"

      if postgresql?
        order << ' NULLS LAST'
      else
        # `field IS NULL` will be `0` for non-NULL columns and `1` for NULL
        # columns. In the (default) ascending order, `0` comes first.
        order.prepend("#{field} IS NULL, ") if direction == 'ASC'
      end

      order
    end

    def self.nulls_first_order(field, direction = 'ASC')
      order = "#{field} #{direction}"

      if postgresql?
        order << ' NULLS FIRST'
      else
        # `field IS NULL` will be `0` for non-NULL columns and `1` for NULL
        # columns. In the (default) ascending order, `0` comes first.
        order.prepend("#{field} IS NULL, ") if direction == 'DESC'
      end

      order
    end

    def self.random
      postgresql? ? "RANDOM()" : "RAND()"
    end

    def self.minute_interval(value)
      postgresql? ? "#{value} * '1 minute'::interval" : "INTERVAL #{value} MINUTE"
    end

    def self.true_value
      if postgresql?
        "'t'"
      else
        1
      end
    end

    def self.false_value
      if postgresql?
        "'f'"
      else
        0
      end
    end

    def self.with_connection_pool(pool_size)
      pool = create_connection_pool(pool_size)

      begin
        yield(pool)
      ensure
        pool.disconnect!
      end
    end

    # Bulk inserts a number of rows into a table, optionally returning their
    # IDs.
    #
    # table - The name of the table to insert the rows into.
    # rows - An Array of Hash instances, each mapping the columns to their
    #        values.
    # return_ids - When set to true the return value will be an Array of IDs of
    #              the inserted rows, this only works on PostgreSQL.
    def self.bulk_insert(table, rows, return_ids: false)
      return if rows.empty?

      keys = rows.first.keys
      columns = keys.map { |key| connection.quote_column_name(key) }
      return_ids = false if mysql?

      tuples = rows.map do |row|
        row.values_at(*keys).map { |value| connection.quote(value) }
      end

      sql = <<-EOF
        INSERT INTO #{table} (#{columns.join(', ')})
        VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
      EOF

      if return_ids
        sql << 'RETURNING id'
      end

      result = connection.execute(sql)

      if return_ids
        result.values.map { |tuple| tuple[0].to_i }
      else
        []
      end
    end

    def self.sanitize_timestamp(timestamp)
      MAX_TIMESTAMP_VALUE > timestamp ? timestamp : MAX_TIMESTAMP_VALUE.dup
    end

    # pool_size - The size of the DB pool.
    # host - An optional host name to use instead of the default one.
    def self.create_connection_pool(pool_size, host = nil)
      # See activerecord-4.2.7.1/lib/active_record/connection_adapters/connection_specification.rb
      env = Rails.env
      original_config = ActiveRecord::Base.configurations

      env_config = original_config[env].merge('pool' => pool_size)
      env_config['host'] = host if host

      config = original_config.merge(env => env_config)

      spec =
        ActiveRecord::
          ConnectionAdapters::
          ConnectionSpecification::Resolver.new(config).spec(env.to_sym)

      ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
    end

    # Disables prepared statements for the current database connection.
    def self.disable_prepared_statements
      config = ActiveRecord::Base.configurations[Rails.env]
      config['prepared_statements'] = false

      ActiveRecord::Base.establish_connection(config)
    end

    def self.connection
      ActiveRecord::Base.connection
    end

    private_class_method :connection

    def self.database_version
      row = connection.execute("SELECT VERSION()").first

      if postgresql?
        row['version']
      else
        row.first
      end
    end

    private_class_method :database_version
  end
end
