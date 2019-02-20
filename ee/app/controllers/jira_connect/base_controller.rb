# frozen_string_literal: true

class JiraConnect::BaseController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  private

  def auth_token
    params[:jwt] || request.headers['authorization'].split(' ').last
  end
end
