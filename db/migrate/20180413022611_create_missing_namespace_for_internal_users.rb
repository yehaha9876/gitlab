class CreateMissingNamespaceForInternalUsers < ActiveRecord::Migration
  DOWNTIME = false

  def up
    fix_internal_user(:ghost)
    # EE only
    fix_internal_user(:support_bot)
  end

  def down
    # no-op
  end

  def fix_internal_user(user_type)
    if user = User.find_by(user_type => true)
      user.ensure_namespace_correct
      user.set_notification_email
      user.save!
    end
  end
end
