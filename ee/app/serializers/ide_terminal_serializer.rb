# frozen_string_literal: true

class IdeTerminalSerializer < BaseSerializer
  entity IdeTerminalEntity

  def represent(resource, opts = {})
    super(IdeTerminal.new(resource), opts)
  end
end
