class EnabledFeatures
  FILE_LOCK = 'GitLab_FileLocks'
  GEO = 'GitLab_Geo'
  ADD_ONS = [FILE_LOCK, GEO]

  DEPLOY_BOARDS = 'deploy_boards'
  PREMIUM_FEATURES = [DEPLOY_BOARDS]

  def self.allow?(name)
    new.allow?(name)
  end

  def allow?(name)
    case name
    when *ADD_ONS
      check_add_on(name)
    when *PREMIUM_FEATURES
      premium_plan?
    end
  end

  private

  def premium_plan?
    current_license&.plan?('premium')
  end

  def current_license
    @license ||= License.current
  end

  def check_add_on(name)
    if premium_plan?
      current_license&.excluded_add_ons.exclude?(name)
    else
      current_license.add_on?(name)
    end
  end
end
