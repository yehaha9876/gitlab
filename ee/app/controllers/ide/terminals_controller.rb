# frozen_string_literal: true

class Ide::TerminalsController < ApplicationController
  before_action :load_project

  def check_config
    #TODO add sha validation
    # result = ::Ci::WebideConfigValidatorService.new(project, current_user, sha: branch_sha).execute
    result = { status: :success }
    if result[:status] == :success
      head :ok
    else
      respond_422
    end
  end

  def create
    binding.pry
  end

  private

  def load_project
    return respond_422 unless project
  end

  def project
    @project ||= Project.find_by_full_path(params[:project])
  end

  def check_config_params

  end

  def branch_sha
    return unless params[:branch].present?

    project.commit(params[:branch])&.id
  end
end
