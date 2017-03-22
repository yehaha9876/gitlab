# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MoveUploadsToSystemDir < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  DIRECTORIES_TO_MOVE = %w(user project note group appeareance)

  def up
    return unless file_storage?

    FileUtils.mkdir_p(new_upload_dir)
    DIRECTORIES_TO_MOVE.each do |dir|
      source = File.join(old_upload_dir, dir)
      destination = File.join(new_upload_dir, dir)
      merge_source_into_destination(source, destination)
    end
  end

  def down
    return unless file_storage?
    return unless File.directory?(new_upload_dir)

    DIRECTORIES_TO_MOVE.each do |dir|
      source = File.join(new_upload_dir, dir)
      destination = File.join(old_upload_dir, dir)
      merge_source_into_destination(source, destination)
    end

    delete_directory_if_empty(new_upload_dir)
  end

  def merge_source_into_destination(source, destination)
    say "Moving #{source} into #{destination}"

    all_files(source).each do |entry|
      directory = File.dirname(entry)
      relative_directory = directory.gsub(source, "")
      full_destination_directory = File.join(destination, relative_directory)

      FileUtils.mkdir_p(full_destination_directory)
      FileUtils.mv(entry, full_destination_directory)

      delete_directory_if_empty(directory)
    end
    delete_directory_if_empty(source)
  end

  def delete_directory_if_empty(directory)
    FileUtils.remove_dir(directory) if File.directory?(directory) && all_files(directory).size == 0
  end

  def all_files(folder)
    Dir.glob(File.join(folder, "**/*.*"))
  end

  def file_storage?
    CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
  end

  def base_directory
    Rails.root
  end

  def old_upload_dir
    File.join(base_directory, "public", "uploads")
  end

  def new_upload_dir
    File.join(base_directory, "public", "uploads", "system")
  end
end
