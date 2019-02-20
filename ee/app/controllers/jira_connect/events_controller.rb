# frozen_string_literal: true

class JiraConnect::EventsController < JiraConnect::BaseController
  def installed
    installation = JiraConnectInstallation.new(install_params)

    if installation.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def uninstalled
    installation = JiraConnectInstallation.find_by_client_key(params[:clientKey])

    if installation.destroy
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def enabled
    installation = JiraConnectInstallation.find_by_client_key(params[:clientKey])
    installation.enable!

    head :ok
  end

  def disabled
    installation = JiraConnectInstallation.find_by_client_key(params[:clientKey])
    installation.disable!

    head :ok
  end

  private

  def install_params
    params.permit(:clientKey, :sharedSecret, :baseUrl).transform_keys { |key| key.underscore }
  end
end
