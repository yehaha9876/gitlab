module SendFileUpload
  def send_upload(file_upload, send_params: {}, redirect_params: {}, attachment: nil)
    render_404 unless file_upload

    if attachment
      redirect_params[:query] = { "response-content-disposition" => "attachment;filename=#{attachment.inspect}" }
      send_params.merge!(filename: attachment, disposition: 'attachment')
    end

    if file_upload.is_a?(String)
      send_file file_upload, send_params
    elsif file_upload.file_storage?
      send_file file_upload.path, send_params
    else
      redirect_to file_upload.url(**redirect_params)
    end
  end
end
