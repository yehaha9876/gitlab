# frozen_string_literal: true

class IdeTerminal
  include ::Gitlab::Routing

  attr_reader :build, :project

  delegate :id, :status, to: :build

  def initialize(build)
    @build = build
    @project = build.project
  end

  def show_path
    ide_terminal_route_generator(:show)
  end

  def retry_path
    ide_terminal_route_generator(:retry)
  end

  def cancel_path
    ide_terminal_route_generator(:cancel)
  end

  def terminal_path
    terminal_project_job_path(project, build, format: :ws)
  end

  private

  def ide_terminal_route_generator(action)
    url_for(action: action,
            controller: 'projects/ide_terminals',
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: build.id,
            only_path: true)
  end
end
