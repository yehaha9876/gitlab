class Projects::ReleaseAssetController < Projects::ApplicationController
  before_action :authorize_download_code!
  before_action :release
  before_action :asset
  before_action :file

  def show
    if file.file_storage?
      send_file file.path, disposition: 'attachment'
    else
      redirect_to file.url
    end
  end

  def update
    if asset.update_attributes(asset_params)
      redirect_to namespace_project_release_tag_path(@project.namespace, @project, release.tag, asset.file)
    else
      redirect_to namespace_project_tag_path(@project.namespace, @project, release.tag)
    end
  end

  def destroy
    if asset.destroy
      redirect_to namespace_project_release_tag_path(@project.namespace, @project, release.tag, asset.file)
    else
      redirect_to namespace_project_tag_path(@project.namespace, @project, release.tag)
    end
  end

  private

  def file
    @file ||= asset.file
  end

  def asset
    @asset ||= release.assets.find_by(file: params[:id])
  end

  def release
    @release ||= @project.releases.find_by(tag: params[:tag_id])
  end

  def asset_params
    params.require(:assets).permit(:file)
  end
end
