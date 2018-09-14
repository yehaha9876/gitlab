# frozen_string_literal: true

class IdeTerminal
  include ::Gitlab::Routing

  DEFAULT_ROUTE = 'project_ide_terminal_path'.freeze

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
    terminal_project_job_path(project, build, format: :ws)
  end

  private

  def route_generator(prefix = nil)
    route = [prefix, DEFAULT_ROUTE].compact.join('_')

    public_send(route, project, build) # rubocop:disable GitlabSecurity/PublicSend
  end
end
