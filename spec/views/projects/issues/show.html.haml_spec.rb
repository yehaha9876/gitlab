# frozen_string_literal: true

require 'spec_helper'

describe 'projects/issues/show' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:project, :repository) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:user) { create(:user) }
  let(:note) { create(:note_on_issue, project: project, noteable: issue, note: user.to_reference) }

  def preload_view_requirements
    user.status
    note.author.status
  end

  def serialize_issuable_sidebar(user, project, merge_request)
    IssueSerializer
      .new(current_user: user, project: project)
      .represent(issue, serializer: 'sidebar')
  end

  before do
    assign(:project, project)
    assign(:issue, issue)
    assign(:note, note)
    assign(:notes, [])
    assign(:noteable, issue)
    assign(:issuable_sidebar, serialize_issuable_sidebar(user, project, issue))

    preload_view_requirements

    allow(view).to receive_messages(current_user: user,
                                    can?: true,
                                    current_application_settings: Gitlab::CurrentSettings.current_application_settings)
  end

  context 'when the issue is closed' do
    before do
      allow(issue).to receive(:closed?).and_return(true)
    end

    it 'shows "Closed (moved)" if an issue has been moved' do
      allow(issue).to receive(:moved?).and_return(true)

      render

      expect(rendered).to have_selector('.status-box-issue-closed:not(.hidden)', text: 'Closed (moved)')
    end

    it 'shows "Closed" if an issue has been moved' do
      render

      expect(rendered).to have_selector('.status-box-issue-closed:not(.hidden)', text: 'Closed')
    end
  end

  context 'when the issue is open' do
    before do
      allow(issue).to receive(:closed?).and_return(false)
      allow(issue).to receive(:disscussion_locked).and_return(false)
    end

    it 'shows "Open" if an issue has been moved' do
      render

      expect(rendered).to have_selector('.status-box-open:not(.hidden)', text: 'Open')
    end
  end
end
