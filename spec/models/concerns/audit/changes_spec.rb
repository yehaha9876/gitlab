require 'spec_helper'

# rubocop:disable RSpec/DescribedClass:
describe Audit::Changes do
  describe '.audit_changes' do
    before do
      stub_const 'FooUser', create(:user)
      FooUser.class_eval do
        include Audit::Changes
        attr_accessor :email_test
        audit_changes :email_test, as: 'email_address', skip_changes: true
      end

      FooUser.current_user = create(:user)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        expect(FooUser).to receive(:email_test_changed?).and_return(false)
        expect_any_instance_of(AuditEventService).not_to receive(:security_event)

        FooUser.update!(name: 'new name')
      end
    end

    describe 'audit changes' do
      it 'calls the audit event service' do
        expect(FooUser).to receive(:email_test_changed?).and_return(true)
        expect_any_instance_of(AuditEventService).to receive(:security_event)

        FooUser.update!(email_test: 'new@email.com')
      end
    end
  end

  describe 'quiet' do
    before do
      stub_const 'FooUser', create(:user)
      FooUser.class_eval do
        include Audit::Changes
        attr_accessor :email_test
      end
    end

    it 'raises error when set to false' do
      FooUser.class_eval do
        audit_changes :email_test, as: 'email_address', skip_changes: true
      end

      expect(FooUser).to receive(:email_test_changed?).and_return(true)
      expect_any_instance_of(AuditEventService).not_to receive(:security_event)

      expect { FooUser.update!(email_test: 'new@email.com') }.to raise_error(NotImplementedError)
    end

    it 'does not raise error when set to true' do
      FooUser.class_eval do
        audit_changes :email_test, as: 'email_address', skip_changes: true, quiet: true
      end

      expect(FooUser).to receive(:email_test_changed?).and_return(true)
      expect_any_instance_of(AuditEventService).to receive(:security_event)

      expect { FooUser.update!(email_test: 'new@email.com') }.not_to raise_error
    end
  end

  describe '.audit_presence' do
    before do
      stub_const 'FooEmail', Email
      FooEmail.class_eval do
        include Audit::Changes
        attr_accessor :email_test
        audit_presence :email_test, as: 'email_address', skip_changes: true
      end
    end

    describe 'audit creation' do
      it 'calls the audit event service' do
        expect_any_instance_of(AuditEventService).to receive(:security_event).and_call_original

        user = create(:user)

        FooEmail.create!(current_user: user, user: user, email: 'test@email.com')
      end
    end

    describe 'audit deletion' do
      it 'calls the audit event service' do
        user = create(:user)
        foo_email = FooEmail.create!(current_user: user, user: user, email: 'test@email.com')

        expect_any_instance_of(AuditEventService).to receive(:security_event).and_call_original

        foo_email.destroy!
      end
    end
  end
end
# rubocop:enable RSpec/DescribedClass:
