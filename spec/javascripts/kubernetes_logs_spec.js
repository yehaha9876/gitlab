import KubernetesLogs from 'ee/kubernetes_logs';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

describe('Kubernetes Logs', () => {
  const fixtureTemplate = 'static/environments_logs.html.raw';
  const mockPodName = 'production-tanuki-1';
  const logMockPath = '/root/kubernetes-app/environments/1/logs';
  let kubernetesLogContainer;
  let kubernetesLog;
  let response;
  let mock;
  preloadFixtures(fixtureTemplate);

  beforeEach(() => {
    loadFixtures(fixtureTemplate);

    spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => [mockPodName]);

    response = {
      data: {
        logs: [
          'Sweet log',
        ],
      },
    };

    mock = new MockAdapter(axios);

    mock.onGet(`${logMockPath}?pod_name=${mockPodName}`).reply(() => [200, response]);

    kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
  });

  it('queries the pod log data', (done) => {
    kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

    kubernetesLog.getPodLogs()
    .then(() => {
      // TODO: Add expectations here
      done();
    })
    .catch(() => {
      // TODO: Add expectation here
      done();
    });
  });
});
