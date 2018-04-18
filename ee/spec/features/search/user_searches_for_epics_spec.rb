require 'spec_helper'

describe 'User searches for epics' do
  set(:user) { create(:user) }
  let!(:group) { create(:group, :public, name: 'Shop') }
  let!(:epic)  { create(:epic, group: group, title: 'An interesting epic') }
  let!(:epic2) { create(:epic, title: 'No access to this') }

  context 'when signed in' do
    before do
      group.add_master(user)
      sign_in(user)

      visit(search_path)
    end

    include_examples 'top right search form'

    it 'finds an epic' do
      fill_in('dashboard_search', with: epic.title)
      find('.btn-search').click

      page.within('.search-filter') do
        click_link('Epics')
      end

      page.within('.results') do
        expect(find(:css, '.search-results')).to have_link(epic.title).and have_no_link(epic2.title)
      end
    end

    context 'when on a group page' do
      it 'does not allow epic searches' do
        visit(search_path(group_id: group.id))

        fill_in('search', with: 'epic.title')
        click_button('Search')

        expect(page).not_to have_link('Epics')
      end
    end
  end

  context 'when signed out' do
    include_examples 'top right search form'

    it 'does not find any epics' do
      visit(search_path)

      fill_in('dashboard_search', with: epic.title[0..3])
      click_button('Search')

      expect(page).not_to have_link(epic.title)
    end
  end
end
