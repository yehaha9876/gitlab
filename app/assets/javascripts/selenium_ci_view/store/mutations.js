import * as types from './mutation_types';

export default {
  [types.REQUEST_SESSION_LOG](state, sessionId) {
    state.currentSessionId = sessionId;
    state.isLoadingSession = true;
  },
  [types.RECEIVE_SESSION_LOG_SUCCESS](state, data) {
    state.sessionLog = data;
    state.isLoadingSession = false;
  },
  [types.REQUEST_SESSION_LOG_ERROR](state, error) {
    state.errorSession = error;
    state.isLoadingSession = false;
  },

  [types.RECEIVE_BASE_ARTIFACT_ENDPOINT_SUCCESS](state, baseArtifactEndpoint) {
    state.baseArtifactEndpoint = baseArtifactEndpoint;
  },

  [types.RECEIVE_SESSION_IDS_SUCCESS](state, sessionIds) {
    state.sessionIds = sessionIds;
  },
};
