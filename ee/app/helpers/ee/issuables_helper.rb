module EE
  module IssuablesHelper
    def render_sidebar_epic(issuable)
      sidebar = render 'shared/issuable/sidebar_item_epic', issuable: issuable
      promotion = render 'shared/promotions/promote_epics'

      "#{sidebar}\n#{promotion}"
    end

    def issuable_sidebar_options(issuable, can_edit_issuable)
      super.merge(
        weightOptions: ::Issue.weight_options,
        weightNoneValue: ::Issue::WEIGHT_NONE
      )
    end
  end
end
