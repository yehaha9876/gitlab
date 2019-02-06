# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20190206144959_change_issuable_states_to_integer.rb')

describe ChangeIssuableStatesToInteger, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:issues) { table(:issues) }
  let(:migration) { described_class.new }

  before do
    @group = namespaces.create!(name: 'gitlab', path: 'gitlab')
    @project = projects.create!(namespace_id: @group.id)
  end

  describe '#up' do
    it 'migrates state column to integer' do
      opened_issue = issues.create!(description: "first", state: 'opened')
      closed_issue = issues.create!(description: "second", state: 'closed')
      nil_state_issue = issues.create!(description: "third", state: nil)

      migration.up

      issues.reset_column_information
      expect(opened_issue.reload.state).to eq(Issue.states.opened)
      expect(closed_issue.reload.state).to eq(Issue.states.closed)
      expect(nil_state_issue.reload.state).to eq(nil)
    end
  end

  # describe '#down' do
  #   it 'migrates state column to string' do
  #     merge_requests.create!(target_project_id: @project.id, source_project_id: @project.id, target_branch: 'feature1', source_branch: 'master', description: "description", state: 'opened')
  #     merge_requests.create!(target_project_id: @project.id, source_project_id: @project.id, target_branch: 'feature2', source_branch: 'master', description: "description", state: 'closed')
  #     merge_requests.create!(target_project_id: @project.id, source_project_id: @project.id, target_branch: 'feature3', source_branch: 'master', description: "description", state: nil)
  #   end
  # end
end
