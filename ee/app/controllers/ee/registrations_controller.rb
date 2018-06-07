module EE
  module RegistrationsController
    extend ActiveSupport::Concern

    def create
      if (params[:new_user][:terms_of_service_opted_in].present? && params[:new_user][:terms_of_service_opted_in] == '0') ||
          (params[:new_user][:privacy_policy_opted_in].present? && params[:new_user][:privacy_policy_opted_in] == '0')
        flash[:alert] = 'You must accept our terms of service and privacy policy in order to register an account at GitLab.com'
        redirect_to(new_user_session_path)
      else
        super
      end
    end

    private

    def sign_up_params
      clean_params = params.require(:user).permit(:username, :email, :email_confirmation, :name, :password, :email_opted_in)

      if clean_params[:email_opted_in] == '1'
        clean_params[:email_opted_in_ip] = request.remote_ip
        clean_params[:email_opted_in_source_id] = User::EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM
        clean_params[:email_opted_in_at] = Time.zone.now
      end

      clean_params
    end
  end
end
