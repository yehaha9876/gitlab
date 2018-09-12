# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::AlertsController do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:environment) { create(:environment, project: project) }
  set(:metric) { create(:prometheus_metric, project: project) }

  before do
    stub_licensed_features(prometheus_alerts: true)
    project.add_master(user)
    sign_in(user)
  end

  shared_examples 'unlicensed' do
    before do
      stub_licensed_features(prometheus_alerts: false)
    end

    it 'returns not_found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'project non-specific environment' do |status|
    set(:other) { create(:environment) }

    it "returns #{status}" do
      subject(environment_id: other)

      expect(response).to have_gitlab_http_status(status)
    end
  end

  shared_examples 'project non-specific metric' do |status|
    set(:other) { create(:prometheus_metric) }

    it "returns #{status}" do
      subject(id: other.id)

      expect(response).to have_gitlab_http_status(status)
    end
  end

  describe 'GET #index' do
    def subject(opts = {})
      get :index, params: request_params(opts, environment_id: environment)
    end

    context 'when project has no prometheus alert' do
      it 'returns an empty response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    context 'when project has prometheus alerts' do
      let(:production) { create(:environment, project: project) }
      let(:staging) { create(:environment, project: project) }
      let(:json_alert_ids) { json_response.map { |alert| alert['id'] } }

      let!(:production_alerts) do
        create_list(:prometheus_alert, 2, project: project, environment: production)
      end

      let!(:staging_alerts) do
        create_list(:prometheus_alert, 1, project: project, environment: staging)
      end

      it 'contains prometheus alerts only for the production environment' do
        subject(environment_id: production)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(2)
        expect(json_alert_ids).to eq(production_alerts.map(&:id))
      end

      it 'contains prometheus alerts only for the staging environment' do
        subject(environment_id: staging)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(1)
        expect(json_alert_ids).to eq(staging_alerts.map(&:id))
      end

      it 'does not return prometheus alerts without environment' do
        subject(environment_id: nil)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end

      context 'with project non-specific environment' do
        let(:other) { create(:environment) }

        it 'does not return prometheus alerts' do
          subject(environment_id: other)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_empty
        end
      end
    end

    it_behaves_like 'unlicensed'
  end

  describe 'GET #show' do
    let(:alert) do
      create(:prometheus_alert,
             project: project,
             environment: environment,
             prometheus_metric: metric)
    end

    def subject(opts = {})
      get :show, params: request_params(opts,
        id: alert.prometheus_metric_id,
        environment_id: environment
      )
    end

    context 'when alert does not exist' do
      it 'returns not_found' do
        subject(id: 0)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when alert exists' do
      let(:alert_params) do
        {
          'id' => alert.id,
          'title' => alert.title,
          'query' => alert.query,
          'operator' => alert.computed_operator,
          'threshold' => alert.threshold,
          'alert_path' => alert_path(alert)
        }
      end

      it 'renders the alert' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(alert_params)
      end

      it_behaves_like 'unlicensed'
      it_behaves_like 'project non-specific environment', :not_found
      it_behaves_like 'project non-specific metric', :not_found
    end
  end

  describe 'POST #notify' do
    let(:notify_service) { spy }

    before do
      expect(Projects::Prometheus::Alerts::NotifyService)
        .to receive(:new)
        .and_return(notify_service)
        .with(project, user, duck_type(:permitted?))
    end

    it 'returns ok if notification succeeds' do
      expect(notify_service).to receive(:execute).and_return(true)

      post :notify, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns unprocessable entity if notification fails' do
      expect(notify_service).to receive(:execute).and_return(false)

      post :notify, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    context 'bearer token' do
      context 'when set' do
        it 'extracts bearer token' do
          request.headers['HTTP_AUTHORIZATION'] = 'Bearer some token'

          expect(notify_service).to receive(:execute).with('some token')

          post :notify, params: project_params, as: :json
        end

        it 'pass nil if cannot extract a non-bearer token' do
          request.headers['HTTP_AUTHORIZATION'] = 'some token'

          expect(notify_service).to receive(:execute).with(nil)

          post :notify, params: project_params, as: :json
        end
      end

      context 'when missing' do
        it 'passes nil' do
          expect(notify_service).to receive(:execute).with(nil)

          post :notify, params: project_params, as: :json
        end
      end
    end
  end

  describe 'POST #create' do
    let(:schedule_update_service) { spy }

    let(:alert_params) do
      {
        'title' => metric.title,
        'query' => metric.query,
        'operator' => '>',
        'threshold' => 1.0
      }
    end

    def subject(opts = {})
      post :create, params: request_params(opts,
        operator: '>',
        threshold: '1',
        environment_id: environment,
        prometheus_metric_id: metric
      )
    end

    it 'creates a new prometheus alert' do
      allow(::Clusters::Applications::ScheduleUpdateService)
        .to receive(:new).and_return(schedule_update_service)

      subject

      expect(schedule_update_service).to have_received(:execute)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(alert_params)
    end

    it 'returns no_content for an invalid metric' do
      subject(prometheus_metric_id: 'invalid')

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it_behaves_like 'unlicensed'
    it_behaves_like 'project non-specific environment', :no_content
  end

  describe 'PUT #update' do
    let(:schedule_update_service) { spy }

    let(:alert) do
      create(:prometheus_alert,
             project: project,
             environment: environment,
             prometheus_metric: metric)
    end

    let(:alert_params) do
      {
        'id' => alert.id,
        'title' => alert.title,
        'query' => alert.query,
        'operator' => '<',
        'threshold' => alert.threshold,
        'alert_path' => alert_path(alert)
      }
    end

    before do
      allow(::Clusters::Applications::ScheduleUpdateService)
        .to receive(:new).and_return(schedule_update_service)
    end

    def subject(opts = {})
      put :update, params: request_params(opts,
        id: alert.prometheus_metric_id,
        operator: '<',
        environment_id: alert.environment
      )
    end

    it 'updates an already existing prometheus alert' do
      expect do
        subject(operator: '<')
      end.to change { alert.reload.operator }.to('lt')

      expect(schedule_update_service).to have_received(:execute)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(alert_params)
    end

    it_behaves_like 'unlicensed'
    it_behaves_like 'project non-specific environment', :not_found
    it_behaves_like 'project non-specific metric', :not_found
  end

  describe 'DELETE #destroy' do
    let(:schedule_update_service) { spy }

    let!(:alert) do
      create(:prometheus_alert, project: project, prometheus_metric: metric)
    end

    before do
      allow(::Clusters::Applications::ScheduleUpdateService)
        .to receive(:new).and_return(schedule_update_service)
    end

    def subject(opts = {})
      delete :destroy, params: request_params(opts,
        id: alert.prometheus_metric_id,
        environment_id: alert.environment
      )
    end

    it 'destroys the specified prometheus alert' do
      expect do
        subject
      end.to change { PrometheusAlert.count }.from(1).to(0)

      expect(schedule_update_service).to have_received(:execute)
    end

    it_behaves_like 'unlicensed'
    it_behaves_like 'project non-specific environment', :not_found
    it_behaves_like 'project non-specific metric', :not_found
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end

  def request_params(opts = {}, defaults = {})
    project_params(opts.reverse_merge(defaults))
  end

  def alert_path(alert)
    project_prometheus_alert_path(project, alert.prometheus_metric_id,
                                  environment_id: alert.environment,
                                  format: :json)
  end
end
