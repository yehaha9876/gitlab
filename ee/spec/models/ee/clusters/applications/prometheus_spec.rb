# frozen_string_literal: true

require 'rails_helper'

describe Clusters::Applications::Prometheus do
  describe 'transition to updating' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    subject { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

    it 'sets last_update_started_at to now' do
      Timecop.freeze do
        expect { subject.make_updating }.to change { subject.reload.last_update_started_at }.to be_within(1.second).of(Time.now)
      end
    end

    context 'application install previously errored with older version' do
      subject { create(:clusters_applications_prometheus, :installed, cluster: cluster, version: '6.7.2') }

      it 'updates the application version' do
        subject.make_updating

        expect(subject.reload.version).to eq('6.7.3')
      end
    end
  end

  describe 'alert manager token' do
    subject { create(:clusters_applications_prometheus) }

    context 'when not set' do
      it 'is empty by default' do
        expect(subject.alert_manager_token).to be_nil
        expect(subject.encrypted_alert_manager_token).to be_nil
        expect(subject.encrypted_alert_manager_token_iv).to be_nil
      end

      describe '#generate_alert_manager_token!' do
        it 'generates a token' do
          subject.generate_alert_manager_token!

          expect(subject.alert_manager_token).to match(/\A\h{32}\z/)
        end
      end
    end

    context 'when set' do
      let(:token) { SecureRandom.hex }

      before do
        subject.update!(alert_manager_token: token)
      end

      it 'reads the token' do
        expect(subject.alert_manager_token).to eq(token)
        expect(subject.encrypted_alert_manager_token).not_to be_nil
        expect(subject.encrypted_alert_manager_token_iv).not_to be_nil
      end

      describe '#generate_alert_manager_token!' do
        it 'does not re-generate the token' do
          subject.generate_alert_manager_token!

          expect(subject.alert_manager_token).to eq(token)
        end
      end
    end
  end
end
