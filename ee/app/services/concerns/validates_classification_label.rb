module ValidatesClassificationLabel
  def classification_label_rejection_reason
    return unless EE::Gitlab::ExternalAuthorization.enabled?

    new_label = params[:external_authorization_classification_label].presence
    new_label ||= ::Gitlab::CurrentSettings.current_application_settings
                    .external_authorization_service_default_label

    unless EE::Gitlab::ExternalAuthorization.access_allowed?(current_user, new_label, project.full_path)
      reason_from_service = EE::Gitlab::ExternalAuthorization.rejection_reason(current_user, new_label).presence
      reason_from_service || _("Access to '%{classification_label}' not allowed") % { classification_label: new_label }
    end
  end
end
