class MergeRequestPolicy < IssuablePolicy
  prepend EE::MergeRequestPolicy

  rule { can?(:read_merge_request) | visible_to_user }.enable :read_merge_request_iid
end
