# frozen_string_literal: true

class IdeTerminalSerializer < BaseSerializer
  entity IdeTerminalEntity

  def represent(resource, opts = {})
    resource = IdeTerminal.new(resource) if resource.is_a?(Ci::Build)

    super
  end
end
