module Search
  class SnippetService
    include Gitlab::CurrentSettings
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      if current_application_settings.elasticsearch_search?
        Gitlab::Elastic::SnippetSearchResults.new(current_user,
                                                  params[:search])
      else
        snippets = SnippetsFinder.new(current_user).execute

        Gitlab::SnippetSearchResults.new(snippets, params[:search])
      end
    end
  end
end
