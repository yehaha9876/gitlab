# frozen_string_literal: true

class IdeTerminalEntity < Grape::Entity
  expose :id
  expose :status
  expose :show_path
  expose :cancel_path
  expose :retry_path
  expose :terminal_path
end
