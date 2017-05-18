require 'spec_helper'

describe Audit::Changes do
  before do
    stub_const 'FooUser', create(:user)
    FooUser.class_eval{ include Audit::Changes }
    FooUser.class_eval{ audit_changes :email, as: 'email_address' }
  end

  describe "non audit changes" do
    it 'does not call the audit event service' do
      expect(AuditEventService).not_to receive(:new)

      FooUser.update(name: 'new name')
    end
  end

  describe "audit changes" do
    it 'calls the audit event service' do
      expect(AuditEventService).to receive(:new)

      FooUser.update(email: 'new@email.com')
    end
  end
end
