module MergeRequestFinder
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  override :filter_items
  def filter_items(items)
    by_approvers(super(items))
  end

  def by_approvers(items)
    MergeRequests::ByApproversFinder
      .call(items, params[:approver_usernames], params[:approver_id])
  end

  class_methods do
    extend ::Gitlab::Utils::Override

    override :scalar_params
    def scalar_params
      @scalar_params ||= super + [:approver_id]
    end

    def array_params
      @array_params ||= super.merge(approver_usernames: [])
    end
  end
end
