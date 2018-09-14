# frozen_string_literal: true

class IdeController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  PROJECT_FULLPATH_REGEX = %r{project/(?<project>\w+/\w+)(/|$)}.freeze

  layout 'fullscreen'

  def index
    return render_404 unless project

    @settings = WebIdeSettings.new(project, current_user)
  end

  def project
    strong_memoize(:project) do
      full_path = params[:vueroute]&.match(PROJECT_FULLPATH_REGEX)

      Project.find_by_full_path(full_path[:project]) if full_path
    end
  end
end
