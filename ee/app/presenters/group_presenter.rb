# frozen_string_literal: true

class GroupPresenter < Gitlab::View::Presenter::Delegated
  presents :group

  def default_view
    return anonymous_group_view unless current_user

    case group_view
    when 'security_dashboard'
      'groups/security/dashboard/show'
    when 'details'
      'groups/details'
    else
      raise ArgumentError, "Unknown group_view setting '#{group_view}' for a user #{current_user}"
    end
  end

  def default_view_supports_request_format?
    if request.format.html?
      true
    elsif request.format.atom?
      supports_atom_request_format?
    else
      false
    end
  end

  private

  def group_view
    strong_memoize(:group_view) do
      current_user&.group_view
    end
  end

  def anonymous_group_view
    'groups/details'
  end

  def supports_atom_request_format?
    group_view != 'security_dashboard'
  end
end
