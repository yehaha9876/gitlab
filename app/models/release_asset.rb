class ReleaseAsset < ActiveRecord::Base
  belongs_to :release
  belongs_to :project

  before_save :update_size, if: :file_changed?
  before_save :update_file_type, if: :file_changed?
  before_save :update_file_content, if: :file_changed?

  #validates :file_architecture, presence: true, if: :debian?
  #validates :file_version, presence: true, if: :debian?

  enum file_type: {
    unknown: nil,
    debian: 1
  }

  mount_uploader :file, ReleaseAssetUploader

  def debian_control
    return unless file_details

    details = file_details.strip_heredoc
    details = details.match(/Package:.*/m)[0].to_s
    details.strip
  end

  private

  def update_size
    self.size =
      if file.exists?
        file.size
      else
        nil
      end
  end

  def update_file_type
    self.file_type = 
      if file.filename.ends_with?('.deb')
        :debian
      else
        unknown
      end
  end

  def update_file_content
    self.file_details = nil
    self.file_version = nil
    self.file_architecture = nil
    self.md5sum = Digest::MD5.file(file.path).hexdigest
    self.sha1sum = Digest::SHA1.file(file.path).hexdigest
    self.sha256sum = Digest::SHA256.file(file.path).hexdigest
    self.sha512sum = Digest::SHA512.file(file.path).hexdigest

    case
    when self.debian?
      self.file_details = `dpkg -I "#{file.path}"`
      self.file_architecture = self.file_details.match(/Architecture:\s*(.*)\s*/)[1].to_s
      self.file_version = self.file_details.match(/Version:\s*(.*)\s*/)[1].to_s
    end
  end
end
