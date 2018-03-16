module EE
  module NotesFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :noteables_for_type
    def noteables_for_type(noteable_type)
      return EpicsFinder.new(@current_user, group_id: @params[:group_id]) if noteable_type == "epic"

      super
    end
  end
end
