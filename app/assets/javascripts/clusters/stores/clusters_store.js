import { s__ } from '../../locale';

export default class ClusterStore {
  constructor() {
    this.state = {
      helpPath: null,
      status: null,
      statusReason: null,
      applications: {
        helm: {
          title: s__('ClusterIntegration|Helm Tiller'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
        },
        ingress: {
          title: s__('ClusterIntegration|Ingress'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
        },
        runner: {
          title: s__('ClusterIntegration|GitLab Runner'),
          status: null,
          statusReason: null,
          requestStatus: null,
          requestReason: null,
        },
      },
    };
  }

  setHelpPath(helpPath) {
    this.state.helpPath = helpPath;
  }

  updateStatus(status) {
    this.state.status = status;
  }

  updateStatusReason(reason) {
    this.state.statusReason = reason;
  }

  updateAppProperty(appId, prop, value) {
    this.state.applications[appId][prop] = value;
  }

  updateStateFromServer(serverState = {}) {
    this.state.status = serverState.status;
    this.state.statusReason = serverState.status_reason;
    serverState.applications.forEach((serverAppEntry) => {
      const {
        name: appId,
        status,
        status_reason: statusReason,
      } = serverAppEntry;

      this.state.applications[appId] = {
        ...(this.state.applications[appId] || {}),
        status,
        statusReason,
      };
    });
  }
}
