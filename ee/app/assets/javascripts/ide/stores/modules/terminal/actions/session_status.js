import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import * as types from '../mutation_types';
import * as messages from '../messages';
import {
  STATUS_RUNNING,
} from '../../../../constants';

export const startPollingSessionStatus = ({ state, dispatch, commit }) => {
  const { sessionPath } = state;

  dispatch('stopPollingSessionStatus');
  dispatch('fetchSessionStatus');

  const interval = setInterval(() => {
    if (!sessionPath) {
      dispatch('stopPollingSessionStatus');
    } else {
      dispatch('fetchSessionStatus');
    }
  }, 5000);

  commit(types.SET_SESSION_STATUS_INTERVAL, interval);
};

export const stopPollingSessionStatus = ({ state, commit }) => {
  const { sessionStatusInterval } = state;

  if (!sessionStatusInterval) {
    return;
  }

  clearInterval(sessionStatusInterval);

  commit(types.SET_SESSION_STATUS_INTERVAL, 0);
};

export const receiveSessionStatusSuccess = ({ commit, dispatch }, data) => {
  const status = data && data.status && data.status.text;

  if (status === 'running') {
    commit(types.SET_SESSION_STATUS, STATUS_RUNNING);
  } else if (status !== 'running' && status !== 'pending') {
    dispatch('killSession');
  }
};

export const receiveSessionStatusError = ({ dispatch }) => {
  flash(messages.UNEXPECTED_ERROR_STATUS);
  dispatch('killSession');
};

export const fetchSessionStatus = ({ dispatch, state }) => {
  const { sessionPath } = state;

  if (!sessionPath) {
    return;
  }

  axios
    .get(sessionPath)
    .then(({ data }) => {
      dispatch('receiveSessionStatusSuccess', data);
    })
    .catch(error => {
      dispatch('receiveSessionStatusError', error);
    });
};
