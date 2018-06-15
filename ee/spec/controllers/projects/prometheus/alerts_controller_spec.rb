require 'spec_helper'

describe Projects::Prometheus::AlertsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:environment) { create(:environment, project: project) }

  before do
    stub_licensed_features(prometheus_alerts: true)
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when project has no prometheus alert' do
      it 'returns an empty response' do
        get :index, project_params

        expect(response).to have_gitlab_http_status(200)
        expect(JSON.parse(response.body)).to be_empty
      end
    end

    context 'when project has prometheus alerts' do
      before do
        create_list(:prometheus_alert, 3, project: project, environment: environment)
      end

      it 'returns an empty response' do
        get :index, project_params

        expect(response).to have_gitlab_http_status(200)
        expect(JSON.parse(response.body).count).to eq(3)
      end
    end
  end

  describe 'GET #show' do
    context 'when unlicensed' do
      it 'renders forbidden' do
        stub_licensed_features(prometheus_alerts: false)

        get :show, project_params(id: PrometheusAlert.all.maximum(:iid) || 0)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when alert does not exist' do
      it 'renders 404' do
        get :show, project_params(id: PrometheusAlert.all.maximum(:iid) || 0)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when alert exists' do
      it 'renders the alert' do
        alert = create(:prometheus_alert, project: project, environment: environment)
        alert_params = {
          "id" => alert.id,
          "iid" => alert.iid,
          "name" => alert.name,
          "query" => alert.query,
          "operator" => alert.operator,
          "threshold" => alert.threshold,
          "alert_path" => Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, alert.iid, environment_id: alert.environment.id, format: :json)
        }

        get :show, project_params(id: alert.iid)

        expect(response).to have_gitlab_http_status(200)
        expect(JSON.parse(response.body)).to include(alert_params)
      end
    end
  end

  describe 'POST #notify' do
    it 'sends a notification' do
      alert = create(:prometheus_alert, project: project, environment: environment)
      notification_service = spy

      alert_params = {
        "alert" => "#{alert.name}_#{alert.iid}",
        "expr" => "#{alert.query} #{alert.operator} #{alert.threshold}",
        "for" => "5m",
        "labels" => { "gitlab" => "hook" },
        "annotations" => {
          "summary" => "Instance {{ $labels.instance }} raised an alert",
          "description" => "{{ $labels.instance }} of job {{ $labels.job }} has been raising an alert for more than 5 minutes."
        }
      }

      allow(NotificationService).to receive(:new).and_return(notification_service)
      expect(notification_service).to receive(:prometheus_alert_fired).with(project, alert_params)

      post :notify, project_params(alerts: [alert])

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'POST #create' do
    context 'when unlicensed' do
      it 'renders forbidden' do
        stub_licensed_features(prometheus_alerts: false)

        post :create, project_params(query: "foo", operator: ">", threshold: "1", name: "bar", environment_id: environment.id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'creates a new prometheus alert' do
      schedule_update_service = spy
      alert_params = {
        "name" => "bar",
        "query" => "foo",
        "operator" => ">",
        "threshold" => 1
      }

      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)
      expect(schedule_update_service).to receive(:execute)

      post :create, project_params(query: "foo", operator: ">", threshold: "1", name: "bar", environment_id: environment.id)

      expect(response).to have_gitlab_http_status(200)
      expect(JSON.parse(response.body)).to include(alert_params)
    end
  end

  describe 'POST #update' do
    let(:schedule_update_service) { spy }
    let(:alert) { create(:prometheus_alert, project: project, environment: environment) }
    let(:alert_params) do
      {
        "id" => alert.id,
        "iid" => alert.iid,
        "name" => "bar",
        "query" => alert.query,
        "operator" => alert.operator,
        "threshold" => alert.threshold,
        "alert_path" => Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, alert.iid, environment_id: alert.environment.id, format: :json)
      }
    end

    before do
      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)
    end

    context 'when unlicensed' do
      it 'renders forbidden' do
        stub_licensed_features(prometheus_alerts: false)

        put :update, project_params(id: alert.iid, name: "bar")

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'updates an already existing prometheus alert' do
      expect(schedule_update_service).to receive(:execute)

      expect do
        put :update, project_params(id: alert.iid, name: "bar")
      end.to change { alert.reload.name }.to("bar")

      expect(response).to have_gitlab_http_status(200)
      expect(JSON.parse(response.body)).to include(alert_params)
    end
  end

  describe 'DELETE #destroy' do
    let(:schedule_update_service) { spy }
    let!(:alert) { create(:prometheus_alert, project: project) }

    before do
      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)
    end

    context 'when unlicensed' do
      it 'renders forbidden' do
        stub_licensed_features(prometheus_alerts: false)

        delete :destroy, project_params(id: alert.iid)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'destroys the specified prometheus alert' do
      expect(schedule_update_service).to receive(:execute)

      expect do
        delete :destroy, project_params(id: alert.iid)
      end.to change { PrometheusAlert.count }.from(1).to(0)
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end