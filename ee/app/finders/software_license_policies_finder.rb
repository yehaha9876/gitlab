# frozen_string_literal: true

class SoftwareLicensePoliciesFinder
  include Gitlab::Allowable
  include FinderMethods

  attr_accessor :current_user, :project

  def initialize(current_user, project, params = {})
    @current_user = current_user
    @project = project
    @params = params
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    return SoftwareLicensePolicy.none unless can?(current_user, :read_software_license_policy, project)

    items = init_collection
    items = by_name(items)
    items = by_name_or_id(items)
    sort(items)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def init_collection
    SoftwareLicensePolicy.includes(:software_license).joins(:software_license).where(project: @project)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_name(items)
    return items unless @params[:name]

    items.where(software_licenses: { name: @params[:name] })
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_name_or_id(items)
    return items unless @params[:name_or_id]

    software_licenses = SoftwareLicense.arel_table
    software_license_policies = SoftwareLicensePolicy.arel_table
    value = @params[:name_or_id]
    items.where(software_licenses[:name].eq(value).or(software_license_policies[:id].eq(value)))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def sort(items)
    return items unless @params[:sort]

    items.order(@params[:sort])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
