# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  include RendersNotes
  include CreatesCommit
  include DiffForPath
  include DiffHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_read_pipeline!, only: [:pipelines]
  before_action :commit
  before_action :define_commit_vars, only: [:show, :diff_for_path, :pipelines]
  before_action :define_note_vars, only: [:show, :diff_for_path]
  before_action :authorize_edit_tree!, only: [:revert, :cherry_pick]

  BRANCH_SEARCH_LIMIT = 1000

  def show
    apply_diff_view_cookie!

    respond_to do |format|
      format.html do
        # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/37599
        Gitlab::GitalyClient.allow_n_plus_1_calls do
          render
        end
      end
      format.diff  { render text: @commit.to_diff }
      format.patch { render text: @commit.to_patch }
    end
  end

  def diff_for_path
    render_diff_for_path(@commit.diffs(diff_options))
  end

  def pipelines
    @pipelines = @commit.pipelines.order(id: :desc)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: {
          pipelines: PipelineSerializer
            .new(project: @project, current_user: @current_user)
            .represent(@pipelines),
          count: {
            all: @pipelines.count
          }
        }
      end
    end
  end

  def branches
    # branch_names_contains/tag_names_contains can take a long time when there are thousands of
    # branches/tags - each `git branch --contains xxx` request can consume a cpu core.
    # so only do the query when there are a manageable number of branches/tags
    @branches_limit_exceeded = @project.repository.branch_count > BRANCH_SEARCH_LIMIT
    @branches = @branches_limit_exceeded ? [] : @project.repository.branch_names_contains(commit.id)

    @tags_limit_exceeded = @project.repository.tag_count > BRANCH_SEARCH_LIMIT
    @tags = @tags_limit_exceeded ? [] : @project.repository.tag_names_contains(commit.id)
    render layout: false
  end

  def revert
    assign_change_commit_vars

    return render_404 if @start_branch.blank?

    @branch_name = create_new_branch? ? @commit.revert_branch_name : @start_branch

    create_commit(Commits::RevertService, success_notice: "The #{@commit.change_type_title(current_user)} has been successfully reverted.",
                                          success_path: -> { successful_change_path }, failure_path: failed_change_path)
  end

  def cherry_pick
    assign_change_commit_vars

    return render_404 if @start_branch.blank?

    @branch_name = create_new_branch? ? @commit.cherry_pick_branch_name : @start_branch

    create_commit(Commits::CherryPickService, success_notice: "The #{@commit.change_type_title(current_user)} has been successfully cherry-picked.",
                                              success_path: -> { successful_change_path }, failure_path: failed_change_path)
  end

  private

  def create_new_branch?
    params[:create_merge_request].present? || !can?(current_user, :push_code, @project)
  end

  def successful_change_path
    referenced_merge_request_url || project_commits_url(@project, @branch_name)
  end

  def failed_change_path
    referenced_merge_request_url || project_commit_url(@project, params[:id])
  end

  def referenced_merge_request_url
    if merge_request = @commit.merged_merge_request(current_user)
      project_merge_request_url(merge_request.target_project, merge_request)
    end
  end

  def commit
    @noteable = @commit ||= @project.commit(params[:id])
  end

  def define_commit_vars
    return git_not_found! unless commit

    opts = diff_options
    opts[:ignore_whitespace_change] = true if params[:format] == 'diff'

    @diffs = commit.diffs(opts)
    @notes_count = commit.notes.count

    @environment = EnvironmentsFinder.new(@project, current_user, commit: @commit).execute.last
  end

  def define_note_vars
    @noteable = @commit
    @note = @project.build_commit_note(commit)

    @new_diff_note_attrs = {
      noteable_type: 'Commit',
      commit_id: @commit.id
    }

    @grouped_diff_discussions = commit.grouped_diff_discussions
    @discussions = commit.discussions

    @notes = (@grouped_diff_discussions.values.flatten + @discussions).flat_map(&:notes)
    @notes = prepare_notes_for_rendering(@notes, @commit)
  end

  def assign_change_commit_vars
    @start_branch = params[:start_branch]
    @commit_params = { commit: @commit }
  end
end
