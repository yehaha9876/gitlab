class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  # If Gitlab::Geo.secondary? changes, we need to reinitialize the  connection
  # properly in the model to avoid requiring a full unicorn restart.
  def self.retrieve_connection
    set_connection! if should_change_connection?
    connection_handler.retrieve_connection(self)
  end

  private

  def self.set_connection!
    if Gitlab::Geo.tracking_connection_available?
      establish_connection Rails.configuration.geo_database
    else
      establish_connection "#{Rails.env}".to_sym
    end
  end

  def self.should_change_connection?
    using_master_connection? && Gitlab::Geo.tracking_connection_available?
  end

  def self.using_master_connection?
    master_connection   = ActiveRecord::Base.connection_config[:database]
    tracking_connection = Geo::BaseRegistry.connection_config[:database]

    master_connection === tracking_connection
  end
end
