class Projects::LfsStorageController < Projects::GitHttpClientController
  include LfsRequest
  include WorkhorseRequest
  include SendFileUpload

  skip_before_action :verify_workhorse_api!, only: [:download, :upload_finalize]

  def download
    lfs_object = LfsObject.find_by_oid(oid)
    unless lfs_object && lfs_object.file.exists?
      render_lfs_not_found
      return
    end

    send_upload(lfs_object.file, send_params: { content_type: "application/octet-stream" })
  end

  def upload_authorize
    set_workhorse_internal_api_content_type

    authorized = LfsObject.new.file.upload_authorize
    authorized.merge!(LfsOid: oid, LfsSize: size)

    render json: authorized
  end

  def upload_finalize
    if store_file(oid, size)
      head 200
    else
      render plain: 'Unprocessable entity', status: 422
    end
  end

  private

  def download_request?
    action_name == 'download'
  end

  def upload_request?
    %w[upload_authorize upload_finalize].include? action_name
  end

  def oid
    params[:oid].to_s
  end

  def size
    params[:size].to_i
  end

  def store_file(oid, size)
    object = LfsObject.find_or_create_by(oid: oid, size: size)
    file_exists = object.file.exists?
    unless file_exists
      object.file.retrive_uploaded_file!(params["file.object_id"], params["file.name"])
      object.file.store!
      object.save!
      file_exists = true
    end

    file_exists && link_to_project(object)
  end

  def link_to_project(object)
    if object && !object.projects.exists?(storage_project.id)
      object.projects << storage_project
      object.save
    end
  end
end
