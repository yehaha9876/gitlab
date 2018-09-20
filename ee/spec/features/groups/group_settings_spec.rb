require 'spec_helper'

describe 'Edit group settings' do
  let(:user)  { create(:user) }
  let(:developer)  { create(:user) }
  let(:group) { create(:group, path: 'foo') }

  before do
    group.add_owner(user)
    group.add_developer(developer)
    sign_in(user)
  end

  describe 'navbar' do
    context 'with LDAP enabled' do
      before do
        allow_any_instance_of(EE::Group).to receive(:ldap_synced?).and_return(true)
        allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
      end

      it 'is able to navigate to LDAP group section' do
        visit edit_group_path(group)

        expect(find('.nav-sidebar')).to have_content('LDAP Synchronization')
      end

      context 'with owners not being able to manage LDAP' do
        it 'is not able to navigate to LDAP group section' do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)

          visit edit_group_path(group)

          expect(find('.nav-sidebar')).not_to have_content('LDAP Synchronization')
        end
      end
    end
  end

  context 'with webhook feature enabled' do
    it 'shows the menu item' do
      stub_licensed_features(group_webhooks: true)

      visit edit_group_path(group)

      within('.nav-sidebar') do
        expect(page).to have_link('Webhooks')
      end
    end
  end

  context 'with webhook feature enabled' do
    it 'shows the menu item' do
      stub_licensed_features(group_webhooks: false)

      visit edit_group_path(group)

      within('.nav-sidebar') do
        expect(page).not_to have_link('Webhooks')
      end
    end
  end

  context 'with project_creation_level feature enabled' do
    it 'shows the selection menu' do
      stub_licensed_features(project_creation_level: true)

      visit edit_group_path(group)

      expect(page).to have_content('Allowed to create projects')
    end
  end

  context 'with project_creation_level feature disabled' do
    it 'shows the selection menu' do
      stub_licensed_features(project_creation_level: false)

      visit edit_group_path(group)

      expect(page).not_to have_content('Allowed to create projects')
    end
  end

  describe 'Member Lock setting' do
    context 'without a license key' do
      before do
        License.delete_all
      end

      it 'is not visible' do
        visit edit_group_path(group)

        expect(page).not_to have_content('Member lock')
      end
    end

    context 'with a license key' do
      it 'is visible' do
        visit edit_group_path(group)

        expect(page).to have_content('Member lock')
      end

      context 'when current user is not the Owner' do
        before do
          sign_in(developer)
        end

        it 'is not visible' do
          visit edit_group_path(group)

          expect(page).not_to have_content('Member lock')
        end
      end
    end
  end

  context 'when custom_project_templates feature' do
    let!(:subgroup) { create(:group, :public, parent: group) }

    shared_examples 'shows custom project templates settings' do
      it 'shows the custom project templates selection menu' do
        expect(page).to have_content('Custom project templates')
      end

      context 'group selection menu', :js do
        before do
          slow_requests do
            find('#s2id_group_custom_project_templates_group_id').click
            wait_for_all_requests
          end
        end

        it 'shows only the subgroups' do
          page.within('.select2-drop .select2-results') do
            results = find_all('.select2-result')

            expect(results.count).to eq 1
            expect(results.last.text).to eq "#{subgroup.full_name} #{subgroup.full_path}"
          end
        end
      end
    end

    shared_examples 'does not show custom project templates settings' do
      it 'does not show the custom project templates selection menu' do
        expect(page).not_to have_content('Custom project templates')
      end
    end

    context 'is enabled' do
      before do
        stub_licensed_features(custom_project_templates: true)
        visit edit_group_path(selected_group)
      end

      context 'when the group is a top parent group' do
        let(:selected_group) { group }

        it_behaves_like 'shows custom project templates settings'
      end

      context 'when the group is a subgroup' do
        let(:selected_group) { subgroup }

        it_behaves_like 'does not show custom project templates settings'
      end
    end

    context 'is disabled' do
      before do
        stub_licensed_features(custom_project_templates: false)
        visit edit_group_path(selected_group)
      end

      context 'when the group is the top parent group' do
        let(:selected_group) { group }

        it_behaves_like 'does not show custom project templates settings'
      end

      context 'when the group is a subgroup' do
        let(:selected_group) { subgroup }

        it_behaves_like 'does not show custom project templates settings'
      end
    end
  end
end
