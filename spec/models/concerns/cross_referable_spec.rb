require 'spec_helper'

describe CrossReferable do
  let(:project)  { create(:project, :repository) }
  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }

  describe '.cross_reference_allowed?' do
    context 'when mentioner is not a MergeRequest' do
      it 'is falsey' do
        mentioner = noteable.dup
        expect(noteable.cross_reference_allowed?(mentioner)).to be_truthy
      end
    end

    context 'when mentioner is a MergeRequest' do
      let(:mentioner) { create(:merge_request, :simple, source_project: project) }
      let(:noteable)  { project.commit }

      it 'is truthy when noteable is in commits' do
        expect(mentioner).to receive(:commits).and_return([noteable])
        expect(noteable.cross_reference_allowed?(mentioner)).to be_falsey
      end

      it 'is falsey when noteable is not in commits' do
        expect(mentioner).to receive(:commits).and_return([])
        expect(noteable.cross_reference_allowed?(mentioner)).to be_truthy
      end
    end

    context 'when notable is an ExternalIssue' do
      let(:noteable) { ExternalIssue.new('EXT-1234', project) }
      it 'is truthy' do
        mentioner = noteable.dup
        expect(noteable.cross_reference_allowed?(mentioner)).to be_falsey
      end
    end
  end
end
