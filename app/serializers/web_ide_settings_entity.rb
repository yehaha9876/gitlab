# frozen_string_literal: true

class WebIdeSettingsEntity < Grape::Entity
  prepend ::EE::WebIdeSettingsEntity

  expose :live_preview_enabled?
end
