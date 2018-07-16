ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable %w(
    event_log
    project_registry
    file_registry
    job_artifact_registry
    vulnerability_feedback
  )
  inflect.acronym 'EE'
end
