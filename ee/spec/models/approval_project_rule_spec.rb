# frozen_string_literal: true

require 'spec_helper'

describe ApprovalProjectRule do
  subject { create(:approval_project_rule) }

  describe '.regular' do
    it 'returns all records' do
      rules = create_list(:approval_project_rule, 2)

      expect(described_class.regular).to contain_exactly(*rules)
    end
  end

  describe '.code_ownerscope' do
    it 'returns nothing' do
      create_list(:approval_project_rule, 2)

      expect(described_class.code_owner).to be_empty
    end
  end

  describe '#regular' do
    it 'returns true' do
      expect(subject.regular).to eq(true)
      expect(subject.regular?).to eq(true)
    end
  end

  describe '#code_owner' do
    it 'returns false' do
      expect(subject.code_owner).to eq(false)
      expect(subject.code_owner?).to eq(false)
    end
  end

  describe '#remove_all_rules_if_only_single_allowed' do
    let!(:other_rule) { create(:approval_project_rule, project: subject.project) }

    context 'when single rule' do
      before do
        allow(License).to receive(:feature_available?).with(:multiple_approval_rules).and_return(false)
      end

      it 'removes other regular rules' do
        subject.destroy

        expect(subject.project.approval_rules.regular.exists?).to eq(false)
      end
    end

    context 'when multiple rules' do
      before do
        allow(License).to receive(:feature_available?).with(:multiple_approval_rules).and_return(true)
      end

      it 'does not remove other rules' do
        subject.destroy

        expect(subject.project.approval_rules.regular.exists?).to eq(true)
      end
    end
  end
end
