module EE
  module BranchesHelper
    def access_levels_data(access_levels)
      access_levels.map do |level|
        if level.type == :user
          {
            id: level.id,
            type: level.type,
            user_id: level.user_id,
            username: level.user.username,
            name: level.user.name,
            avatar_url: level.user.avatar_url
          }
        elsif level.type == :group
          { id: level.id, type: level.type, group_id: level.group_id }
        else
          { id: level.id, type: level.type, access_level: level.access_level }
        end
      end
    end
  end
end
