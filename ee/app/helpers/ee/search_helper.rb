module EE
  module SearchHelper
    extend ::Gitlab::Utils::Override

    override :search_filter_input_options
    def search_filter_input_options(type)
      options = super
      options[:data][:'multiple-assignees'] = 'true' if search_multiple_assignees?(type)

      options
    end

    override :find_project_for_result_blob
    def find_project_for_result_blob(result)
      super || ::Project.find(result['_parent'])
    end

    override :parse_search_result
    def parse_search_result(result)
      return super if result.is_a?(Array)

      blob = ::Gitlab::Elastic::SearchResults.parse_search_result(result)

      [blob.filename, blob]
    end

    override :search_blob_title
    def search_blob_title(project, file_name)
      if @project
        file_name
      else
        (project.full_name + ': ' + content_tag(:i, file_name)).html_safe
      end
    end

    private

    override :categories
    def categories
      # Note: this is to insert epics in a specific location
      ee_order = %i[projects epics issues merge_requests milestones blobs commits wiki_blobs notes]

      categories = super.merge({
        epics: {
          title: 'Epics',
          count: -> { limited_count(@search_results.limited_epics_count) },
          link: search_filter_path(scope: 'epics')
        }
      })

      ee_order.each_with_object({}) { |cat_name, hash| hash[cat_name] = categories[cat_name] }
    end

    override :category_tabs
    def category_tabs
      tabs = super
      tabs.delete(:epics) if @group

      tabs
    end

    override :skipped_global_categories
    def skipped_global_categories
      return super unless ::Gitlab::CurrentSettings.elasticsearch_search?

      []
    end

    def search_multiple_assignees?(type)
      context = @project.presence || @group

      type == :issues &&
        context.feature_available?(:multiple_issue_assignees)
    end
  end
end
