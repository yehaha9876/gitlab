module Projects
  module Security
    class VulnerabilitiesController < Projects::ApplicationController
      # GET /vulnerabilities
      def index
        @severity_counts = @project.vulnerabilities.group(:severity).count
        @vulnerabilities = @project.vulnerabilities.order(:id).all
      end
     end
  end
end
