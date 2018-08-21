# frozen_string_literal: true
require 'spec_helper'

describe Packages::CreatePackageFileService do
  let(:user) { create(:user) }
  let(:package) { create(:maven_package) }

  describe '#execute' do
    context 'with valid params' do
      let(:params) do
        {
          file: Tempfile.new,
          file_name: 'foo.jar'
        }
      end

      it 'creates a new package file' do
        package_file = described_class.new(package, user, params).execute

        expect(package_file).to be_valid
        expect(package_file.file_name).to eq('foo.jar')
        expect(package_file.user).to eq(user)
      end
    end

    context 'file is missing' do
      let(:params) do
        {
          file_name: 'foo.jar'
        }
      end

      it 'raises an error' do
        service = described_class.new(package, user, params)

        expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
