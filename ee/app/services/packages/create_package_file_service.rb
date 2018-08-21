# frozen_string_literal: true
module Packages
  class CreatePackageFileService
    attr_reader :package, :current_user, :params

    def initialize(package, current_user, params)
      @package = package
      @current_user = current_user
      @params = params
    end

    def execute
      package.package_files.create!(
        file:      params[:file],
        size:      params[:size],
        file_name: params[:file_name],
        file_type: params[:file_type],
        file_sha1: params[:file_sha1],
        file_md5:  params[:file_md5],
        user_id:   current_user&.id
      )
    end
  end
end
