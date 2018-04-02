require 'spec_helper'

describe AppearancesHelper do
  before do
    user = create(:user)
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#brand_image' do
    let!(:appearance) { create(:appearance, :with_logo) }

    context 'when there is a logo' do
      it 'returns a path' do
        expect(helper.brand_image).to match(%r(img data-src="/uploads/-/system/appearance/.*png))
      end
    end

    context 'when there is a logo but no associated upload' do
      before do
        # Legacy attachments were not tracked in the uploads table
        appearance.logo.upload.destroy
        appearance.reload
      end

      it 'falls back to using the original path' do
        expect(helper.brand_image).to match(%r(img data-src="/uploads/-/system/appearance/.*png))
      end
    end
  end

  describe '#brand_title' do
    it 'returns the default EE title when no appearance is present' do
      allow(helper)
        .to receive(:current_appearance)
        .and_return(nil)

      expect(helper.brand_title).to eq('GitLab Enterprise Edition')
    end
  end
end
