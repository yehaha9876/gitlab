module EE
  module SearchHelper
    def search_filter_input_options(type)
      options = super
      options[:data][:'multiple-assignees'] = 'true' if search_multiple_assignees?(type)

      options
    end

    def parse_search_result(result)
      if result.is_a?(String)
        Gitlab::ProjectSearchResults.parse_search_result(result)
      else
        Gitlab::Elastic::SearchResults.parse_search_result(result)
      end
    end

    def find_project_for_blob(raw_blob)
      super || Project.find(blob['_parent'])
    end

    def parse_search_blob_file_name(raw_blob)
      return super if raw_blob.is_a?(Array)

      raw_blob.filename
    end

    def parse_search_blob(raw_blob)
      return super if raw_blob.is_a?(Array)

      parse_search_result(raw_blob)
    end

    def parse_search_blob_ref(blob)
      blob.ref
    end

    def search_blob_title(project, file_name)
      content_tag(:strong) do
        if @project
          file_name
        else
          (project.full_name + ': ' + content_tag(:i, file_name)).html_safe
        end
      end
    end

    private

    def search_multiple_assignees?(type)
      context = @project.presence || @group

      type == :issues &&
        context.feature_available?(:multiple_issue_assignees)
    end
  end
end
