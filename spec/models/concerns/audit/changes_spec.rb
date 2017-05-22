require 'spec_helper'

describe Audit::Changes do
  before do
    stub_const 'FooUser', create(:user)
    FooUser.class_eval{ include Audit::Changes }
    FooUser.class_eval{ audit_changes :email, as: 'email_address', column: :notification_email }

    FooUser.current_user = create(:user)
  end

  describe "non audit changes" do
    it 'does not call the audit event service' do
      expect_any_instance_of(AuditEventService).not_to receive(:for_changes)

      FooUser.update!(name: 'new name')
    end
  end

  describe "audit changes" do
    it 'calls the audit event service' do
      expect_any_instance_of(AuditEventService).to receive(:for_changes).and_call_original

      FooUser.update!(email: 'new@email.com')
    end
  end
end
