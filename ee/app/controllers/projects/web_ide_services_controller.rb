# frozen_string_literal: true

class Projects::WebIdeServicesController < Projects::ApplicationController
  SERVICE_PORT = 8080.freeze

  before_action :authenticate_user!
  before_action :build
  before_action :authorize_update_web_ide_terminal!
  before_action :verify_api_request!, only: :service_authorize

  def service_authorize
    set_workhorse_internal_api_content_type
    render json: webide_service(build.service_specification(port: service_port, requested_url: params["requested_uri"]))
  end

  def service_port
    SERVICE_PORT
  end

  private

  def authorize_update_web_ide_terminal!
    return access_denied! unless can?(current_user, :update_web_ide_terminal, build)
  end

  def build
    @build ||= project.builds.find(params[:id])
  end

  def webide_service(service)
    details = {
      'WebIdeService' => {
        'Url' => service[:url],
        'Header' => service[:headers]

      }
    }

    details['WebIdeService']['CAPem'] = service[:ca_pem] if service.key?(:ca_pem)

    details
  end

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end
end
