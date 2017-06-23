module Projects
  module Packages
    class DebsController < Projects::ApplicationController
      before_action :assets
      before_action :packages_content

      def packages
        render plain: packages_content
      end

      def release
        render plain: release_content
      end

      def release_gpg
        render plain: `echo "#{release_content}" | gpg --sign --armor`
      end

      def in_release
        render plain: `echo "#{release_content}" | gpg --sign --armor --clearsign`
      end

      def file
        release = project.releases.find_by(tag: params[:release])
        asset = release.assets.find_by(file: params[:file])
        file = asset.file

        if file.file_storage?
          send_file file.path, disposition: 'attachment'
        else
          redirect_to file.url
        end
      end

      private

      def assets
        @assets ||= project.release_assets.where(file_type: 1).where.not(file_details: nil)
      end

      def packages_content
        @packages_content ||= render_to_string("projects/packages/debs/packages", formats: :text)
      end

      def release_content
        @files = {
          Packages: packages_content,
        }
        @shas = {
          MD5Sum: Digest::MD5,
          SHA1: Digest::SHA1,
          SHA256: Digest::SHA256,
          SHA512: Digest::SHA512,
        }
        @release_content ||= render_to_string("projects/packages/debs/release", formats: :text)
      end
    end
  end
end
