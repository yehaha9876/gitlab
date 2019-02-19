# frozen_string_literal: true

class ProjectCiCdSetting < ActiveRecord::Base
  belongs_to :project, inverse_of: :ci_cd_settings

  default_value_for :merge_pipelines_enabled, false

  # The version of the schema that first introduced this model/table.
  MINIMUM_SCHEMA_VERSION = 20180403035759

  def self.available?
    @available ||=
      ActiveRecord::Migrator.current_version >= MINIMUM_SCHEMA_VERSION
  end

  def self.reset_column_information
    @available = nil
    super
  end
end
