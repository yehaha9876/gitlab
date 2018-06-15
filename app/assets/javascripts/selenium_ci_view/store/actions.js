import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const requestSessionLog = ({ commit }, sessionId) => commit(types.REQUEST_SESSION_LOG, sessionId);
export const receiveSessionLogSuccess = ({ commit }, data) => commit(types.RECEIVE_SESSION_LOG_SUCCESS, data);
export const receiveSessionLogError = ({ commit }, error) => commit(types.REQUEST_SESSION_LOG_ERROR, error);

export const fetchSessionLog = ({ state, dispatch }, sessionId) => {
  dispatch('requestSessionLog', sessionId);

  // TODO: Use proper URL join method or get complete URL from backend
  const sessionEndpoint = `${state.baseArtifactEndpoint}${sessionId}/selenium-logs.json`;

  axios.get(sessionEndpoint)
    .then(({ data }) => dispatch('receiveSessionLogSuccess', data))
    .catch((error) => {
      dispatch('receiveSessionLogError', error);
    });
};

export const receiveBaseArtifactEndpointSuccess = ({ commit }, data) => commit(types.RECEIVE_BASE_ARTIFACT_ENDPOINT_SUCCESS, data);
export const setBaseArtifactEndpoint = ({ state, dispatch }, baseArtifactEndpoint) => {
  dispatch('receiveBaseArtifactEndpointSuccess', baseArtifactEndpoint);
};

export const receiveSessionIdsSuccess = ({ commit }, data) => commit(types.RECEIVE_SESSION_IDS_SUCCESS, data);
export const setSessionIds = ({ state, dispatch }, sessionIds) => {
  dispatch('receiveSessionIdsSuccess', sessionIds);
};
