require "spec_helper"
require Rails.root.join("db", "post_migrate", "20170316163845_move_uploads_to_system_dir.rb")

describe MoveUploadsToSystemDir do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, "tmp", "move_uploads_test") }
  let(:uploads_dir) { File.join(test_dir, "public", "uploads") }
  let(:new_upload_dir) { File.join(uploads_dir, "system") }

  before do
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    FileUtils.mkdir_p(uploads_dir)
    allow(migration).to receive(:base_directory).and_return(test_dir)
    allow(migration).to receive(:say)
  end

  describe "#merge_source_into_destination" do
    let(:source_dir) { File.join(uploads_dir, "user") }
    let(:destination_dir) { File.join(new_upload_dir, "user") }

    before do
      FileUtils.mkdir_p(new_upload_dir)
      FileUtils.mkdir_p(File.join(source_dir, "avatar", "1"))
      FileUtils.touch(File.join(source_dir, "avatar", "1", "avatar.png"))
    end

    it "moves subdirectories with files" do
      migration.merge_source_into_destination(source_dir, destination_dir)

      destination_file = File.join(destination_dir, "avatar", "1", "avatar.png")
      expect(File.exist?(destination_file)).to be(true)
    end

    it "deletes the source directory" do
      migration.merge_source_into_destination(source_dir, destination_dir)

      expect(File.directory?(source_dir)).to be(false)
    end
  end

  describe "#up" do
    it "creates the new directory if needed" do
      migration.up

      expect(File.directory?(new_upload_dir)).to eq(true)
    end

    it "moves all directories to the new place" do
      %w(user project note group appeareance).each do |directory|
        old_directory = File.join(uploads_dir, directory)
        new_directory = File.join(new_upload_dir, directory)

        expect(migration).to receive(:merge_source_into_destination).with(old_directory, new_directory)
      end

      migration.up
    end

    it "doesn't do anything when the storage is object storage" do
      expect(migration).to receive(:file_storage?).and_return(false)

      expect(migration).not_to receive(:merge_source_into_destination)

      migration.up
    end
  end

  describe "#down" do
    it "destroys the new directory if it was empty" do
      FileUtils.mkdir_p(new_upload_dir)

      migration.down

      expect(File.directory?(new_upload_dir)).to eq(false)
    end

    it "doesn't destroy the new directory if there was other content" do
      FileUtils.mkdir_p(File.join(new_upload_dir, "other"))
      FileUtils.touch(File.join(new_upload_dir, "other", "test.txt"))

      migration.down

      expect(File.directory?(new_upload_dir)).to eq(true)
      expect(Dir.entries(new_upload_dir)).to include("other")
    end

    it "doesn't do anything if the new directory didn't exist" do
      FileUtils.remove_dir(new_upload_dir) if File.directory?(new_upload_dir)

      expect(migration).not_to receive(:merge_source_into_destination)

      migration.down
    end

    it "moves all directories to the old place" do
      FileUtils.mkdir_p(new_upload_dir)
      %w(user project note group appeareance).each do |directory|
        old_directory = File.join(uploads_dir, directory)
        new_directory = File.join(new_upload_dir, directory)

        expect(migration).to receive(:merge_source_into_destination).with(new_directory, old_directory)
      end

      migration.down
    end
  end
end
