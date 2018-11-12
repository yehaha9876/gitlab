class CommitValidation
  def execute
  end

  def self.active?(project, new_rev, old_rev)
  end

  def cache!
    cache.store(cache_value, result)
  end

  def cache_value
    CacheValue.new(check_key, cache_by)
  end

  def self.check_key
    :class_name_based_key
  end


  def self.cache_by
    # Some kind of way to tell if this is cached per commit,
    # or if it needs new_rev/old_rev/branch_name
  end
end

class PushRuleCheck < CommitValidation
  def self.check_key
    :push_rule_check
  end

  def self.cache_by
    #TODO
  end
end

class CommitValidationChecker
  def initialize(project)
  end

  def execute(commits_for_rev, validation_cache:)
    return if no_validations_active?

    Something.for(commits).not_allready_passed
                          .any?{|commit| any_validations_failed?(commit) }
  end
end
