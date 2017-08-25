module EE
  module ProtectedRef
    extend ActiveSupport::Concern

    class_methods do
      def protected_ref_access_levels(*types)
        super

        types.each do |type|
          # Overwrite the validation for access levels
          #
          # EE Needs to allow more access levels in the relation:
          # - 1 for each user/group
          # - 1 with the `access_level` (Master, Developer)
          validates :"#{type}_access_levels", length: { is: 1 }, if: -> { false }

          # Returns access levels that grant the specified access type to the given user / group.
          access_level_class = const_get("#{type}_access_level".classify)
          protected_type = self.model_name.singular
          scope(
            :"#{type}_access_by_user",
            -> (user) do
              access_level_class.joins(protected_type.to_sym)
                .where("#{protected_type}_id" => self.ids)
                .merge(access_level_class.by_user(user))
            end
          )
          scope(
            :"#{type}_access_by_group",
            -> (group) do
              access_level_class.joins(protected_type.to_sym)
                .where("#{protected_type}_id" => self.ids)
                .merge(access_level_class.by_group(group))
            end
          )
        end
      end
    end
  end
end
