class Admin::LicensesController < Admin::ApplicationController
  before_action :license, only: [:show, :download, :destroy]
  before_action :require_license, only: [:show, :download, :destroy]

  respond_to :html

  def show
    @previous_licenses = License.previous
  end

  def download
    send_data @license.data, filename: @license.data_filename, disposition: 'attachment'
  end

  def new
    @license = License.new
  end

  def create
    unless license_params.values_at(:data, :data_file).any?(&:present?)
      flash.now[:alert] = "No license was selected."

      @license = License.new
      render :new
      return
    end

    @license = License.new(license_params)

    respond_with(@license, location: admin_license_path) do
      if @license.save
        flash[:notice] = "The license was successfully uploaded and is now active. You can see the details below."
      end
    end
  end

  def destroy
    license.destroy

    if License.current
      flash[:notice] = "The license was removed. GitLab has fallen back on the previous license."
    else
      flash[:alert] = "The license was removed. GitLab now no longer has a valid license."
    end

    redirect_to admin_license_path
  end

  private

  def license
    @license ||= begin
      License.reset_current
      License.current
    end
  end

  def require_license
    return if license

    flash.keep
    redirect_to new_admin_license_path
  end

  def license_params
    license_params = params.require(:license).permit(:data)

    # Wiggle around StrongParameters because data_file is an ::UploadedFile
    data_file = params[:license][:data_file]
    if license_params.permitted? && data_file.present?
      license_params.delete(:data)
      license_params[:data_file] = data_file
    end

    license_params
  end
end
