# == CrossReferable concern
#
# Contains methods related to cross-references.
#
# Used by Issue, ExternalIssue, MergeRequest, Commit, Epic.
#
module CrossReferable
  extend ActiveSupport::Concern

  # Check if a cross-reference is allowed
  #
  # This method prevents adding a "mentioned in !1" note on every single commit
  # in a merge request. Additionally, it prevents the creation of references to
  # external issues (which would fail).
  #
  # mentioner - Mentionable object
  #
  # Returns Boolean
  def cross_reference_allowed?(mentioner)
    true
  end
end
