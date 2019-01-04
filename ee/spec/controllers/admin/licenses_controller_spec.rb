require 'spec_helper'

describe Admin::LicensesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'Upload license' do
    let(:gitlab_license) {
      build(:gitlab_license)
    }

    it 'uploads license key successfully' do
      post :create, params: {
        license: {
          data: gitlab_license.export
        }
      }

      expect(response).to redirect_to admin_license_path
    end

    it 'uploads license file successfully' do
      license_file = Tempfile.open do |file|
        file.write(gitlab_license.export)
        file
      end

      post :create, params: {
        license: {
          data_file: {
            ".path" => license_file.path
          }
        }
      }

      expect(response).to redirect_to admin_license_path
    end

    it 'redirects back when no license is entered/uploaded' do
      post :create, params: { license: { data: '' } }

      expect(response).to redirect_to new_admin_license_path
      expect(flash[:alert]).to include 'Please enter or upload a license.'
    end
  end

  describe 'GET show' do
    context 'with an existent license' do
      it 'renders the license details' do
        allow(License).to receive(:current).and_return(create(:license))

        get :show

        expect(response).to render_template(:show)
      end
    end

    context 'without a license' do
      it 'renders missing license page' do
        allow(License).to receive(:current).and_return(nil)

        get :show

        expect(response).to render_template(:missing)
      end
    end
  end
end
