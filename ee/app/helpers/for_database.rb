# frozen_string_literal: true

module ForDatabase
  def for_database
    original_db_credentials = ActiveRecord::Base.connection_config

    if ::Gitlab::Geo.secondary_with_primary?
      ActiveRecord::Base.remove_connection
      geo_primary_connection = ActiveRecord::Base.establish_connection(GITLAB_GEO_PRIMARY)
      geo_primary_connection.connection.reconnect!
      yield
    else
      super
    end

  ensure
    ActiveRecord::Base.establish_connection(original_db_credentials)
  end
end
