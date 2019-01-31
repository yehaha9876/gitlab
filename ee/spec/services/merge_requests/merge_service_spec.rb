require 'spec_helper'

describe MergeRequests::MergeService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'project has exceeded size limit' do
      before do
        allow(project).to receive(:above_size_limit?).and_return(true)
      end

      it 'persists the correct error message' do
        service.execute(merge_request)

        expect(merge_request.merge_error).to include('This merge request cannot be merged')
      end
    end
  end

  it_behaves_like 'merge validation hooks', persisted: true
end
