# frozen_string_literal: true

module Boards
  class IssuesController < Boards::ApplicationController
    include BoardsResponses
    include ControllerWithCrossProjectAccessCheck

    requires_cross_project_access if: -> { board&.group_board? }

    before_action :whitelist_query_limiting, only: [:index, :update]
    before_action :authorize_read_issue, only: [:index]
    before_action :authorize_create_issue, only: [:create]
    before_action :authorize_update_issue, only: [:update]
    skip_before_action :authenticate_user!, only: [:index]

    # rubocop: disable CodeReuse/ActiveRecord
    def index
      list_service = Boards::Issues::ListService.new(board_parent, current_user, filter_params)
      issues = list_service.execute
      issues = issues.page(params[:page]).per(params[:per] || 20).without_count
      Issue.move_to_end(issues) if Gitlab::Database.read_write?
      issues = issues.preload(:milestone,
                              :assignees,
                              project: [
                                  :route,
                                  {
                                      namespace: [:route]
                                  }
                              ],
                              labels: [:priorities],
                              notes: [:award_emoji, :author]
                             )

      render_issues(issues, list_service.metadata)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create
      service = Boards::Issues::CreateService.new(board_parent, project, current_user, issue_params)
      issue = service.execute

      if issue.valid?
        render json: serialize_as_json(issue)
      else
        render json: issue.errors, status: :unprocessable_entity
      end
    end

    def update
      service = Boards::Issues::MoveService.new(board_parent, current_user, move_params)

      if service.execute(issue)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def render_issues(issues, metadata)
      data = { issues: serialize_as_json(issues) }
      data.merge!(metadata)

      render json: data
    end

    def issue
      @issue ||= issues_finder.find(params[:id])
    end

    def filter_params
      params.merge(board_id: params[:board_id], id: params[:list_id])
        .reject { |_, value| value.nil? }
    end

    def issues_finder
      if board.group_board?
        IssuesFinder.new(current_user, group_id: board_parent.id)
      else
        IssuesFinder.new(current_user, project_id: board_parent.id)
      end
    end

    def project
      @project ||= if board.group_board?
                     Project.find(issue_params[:project_id])
                   else
                     board_parent
                   end
    end

    def move_params
      params.permit(:board_id, :id, :from_list_id, :to_list_id, :move_before_id, :move_after_id)
    end

    def issue_params
      params.require(:issue)
        .permit(:title, :milestone_id, :project_id)
        .merge(board_id: params[:board_id], list_id: params[:list_id], request: request)
    end

    def serialize_as_json(resource)
      resource.as_json(
        only: [:id, :iid, :project_id, :title, :confidential, :due_date, :relative_position, :weight, :time_estimate],
        labels: true,
        issue_endpoints: true,
        include_full_project_path: board.group_board?,
        include: {
          project: { only: [:id, :path] },
          assignees: { only: [:id, :name, :username], methods: [:avatar_url] },
          milestone: { only: [:id, :title] }
        }
      )
    end

    def whitelist_query_limiting
      # Also see https://gitlab.com/gitlab-org/gitlab-ce/issues/42439
      Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42428')
    end
  end
end
