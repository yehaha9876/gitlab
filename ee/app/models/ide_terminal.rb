# frozen_string_literal: true

class IdeTerminal
  attr_reader :build, :project

  delegate :id, :status, to: :build

  def initialize(build)
    @build = build
    @project = build.project
  end

  def show_path
    route_generator
  end

  def retry_path
    route_generator(:retry)
  end

  def cancel_path
    route_generator(:cancel)
  end

  def terminal_path
    route_generator(:terminal)
  end

  private

  def route_generator(route = nil)
    route = [route, 'project_ide_terminal_path'].compact.join('_')

    Gitlab::Routing.url_helpers.public_send(route, project, build) # rubocop:disable GitlabSecurity/PublicSend
  end
end
