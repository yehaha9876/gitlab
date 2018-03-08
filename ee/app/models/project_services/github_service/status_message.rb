class GithubService
  class StatusMessage
    include Gitlab::Routing

    attr_reader :sha, :target_url

    class PipelineOverview < self
      def initialize(project, params)
        super(sha: params[:sha],
              context_name: params[:ref],
              status: params[:status],
              detailed_status: params[:detailed_status],
              target_url: project_pipeline_url(project, params[:id]))
      end
    end

    class ForBuild < self
      def initialize(project, params, sha:)
        super(sha: sha,
              context_name: params[:stage],
              status: params[:status],
              detailed_status: params[:detailed_status],
              target_url: project_build_url(project, params[:id]))
      end
    end

    def initialize(params)
      @sha = params[:sha]
      @context_name = params[:context_name]
      @gitlab_status = params[:status]
      @detailed_status = params[:detailed_status]
      @target_url = params[:target_url]
    end

    def context
      "ci/gitlab/#{@context_name}".truncate(255)
    end

    def description
      "Pipeline #{@detailed_status} on GitLab".truncate(140)
    end

    def status
      case @gitlab_status.to_s
      when 'created',
           'pending',
           'running',
           'manual'
        :pending
      when 'success',
           'skipped'
        :success
      when 'failed'
        :failure
      when 'canceled'
        :error
      end
    end

    def status_options
      {
        context: context,
        description: description,
        target_url: target_url
      }
    end

    def self.pipeline_overview(project, data)
      PipelineOverview.new(project, data[:object_attributes])
    end

    def self.for_pipeline_data(project, data)
      messages = [pipeline_overview(project, data)]

      messages += data[:builds].map do |build|
        ForBuild.new(project, build, sha: data[:object_attributes][:sha])
      end
    end
  end
end
