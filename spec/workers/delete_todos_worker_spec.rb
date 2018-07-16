require 'spec_helper'

describe DeleteTodosWorker do
  it "calls the DeleteRestrictedTodosService with the params it was given" do
    service = double
    expect(DeleteRestrictedTodosService).to receive(:new)
      .with(
        private_project_id: 100, confidential_issue_id: 200,
        removed_user_id: nil, private_group_id: nil
      )
      .and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform('private_project_id' => 100, 'confidential_issue_id' => 200)
  end
end
