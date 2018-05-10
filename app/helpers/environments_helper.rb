module EnvironmentsHelper
  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end

  def format_kube_logs(logs)
    logs.strip.gsub("\n", "<br>").html_safe
  end
end
