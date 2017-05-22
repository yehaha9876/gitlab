require 'spec_helper'

describe Audit::Changes do
  before do
    stub_const 'FooUser', create(:user)
    FooUser.class_eval do
      include Audit::Changes
      attr_accessor :email_test
      audit_changes :email_test, as: 'email_address', skip_changes: true
    end

    FooUser.current_user = create(:user)
  end

  describe "non audit changes" do
    it 'does not call the audit event service' do
      expect(FooUser).to receive(:email_test_changed?).and_return(false)
      expect_any_instance_of(AuditEventService).not_to receive(:security_event)

      FooUser.update!(name: 'new name')
    end
  end

  describe "audit changes" do
    it 'calls the audit event service' do
      expect(FooUser).to receive(:email_test_changed?).and_return(true)
      expect_any_instance_of(AuditEventService).to receive(:security_event)

      FooUser.update!(email_test: 'new@email.com')
    end
  end
end
