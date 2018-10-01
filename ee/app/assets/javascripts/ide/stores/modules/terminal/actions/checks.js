import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';
import * as types from '../mutation_types';
import * as messages from '../messages';
import { WEB_IDE_JOB_TAG } from '../../../../constants';

export const requestConfigCheck = ({ commit }) => {
  commit(types.REQUEST_CONFIG_CHECK);
};

export const receiveConfigCheckSuccess = ({ commit }) => {
  commit(types.SET_ENABLED, true);
  commit(types.RECEIVE_CONFIG_CHECK_SUCCESS);
};

export const receiveConfigCheckError = ({ commit, state }, e) => {
  const { status } = e.response;
  const { paths } = state;

  if (status !== httpStatus.FORBIDDEN) {
    commit(types.SET_ENABLED, true);
  }

  const errorMessage = messages.configCheckError(status, paths.ciYamlHelpPath);
  commit(types.RECEIVE_CONFIG_CHECK_ERROR, errorMessage);
};

export const fetchConfigCheck = ({ dispatch, rootState, rootGetters }) => {
  dispatch('requestConfigCheck');

  const { currentBranchId } = rootState;
  const { currentProject } = rootGetters;

  axios
    .post(`/${currentProject.path_with_namespace}/ide_terminals/check_config`, {
      branch: currentBranchId,
      format: 'json',
    })
    .then(() => {
      dispatch('receiveConfigCheckSuccess');
    })
    .catch(e => {
      dispatch('receiveConfigCheckError', e);
    });
};

export const requestRunnersCheck = ({ commit }) => {
  commit(types.REQUEST_RUNNERS_CHECK);
};

export const receiveRunnersCheckSuccess = ({ commit, dispatch, state }, data) => {
  if (data.length) {
    commit(types.RECEIVE_RUNNERS_CHECK_SUCCESS);
  } else {
    const { paths } = state;
    dispatch('handleRunnersCheckError', messages.runnersCheckError(paths.ciRunnersHelpPath));
  }
};

export const receiveRunnersCheckError = ({ dispatch }) => {
  dispatch('handleRunnersCheckError', messages.UNEXPECTED_ERROR_CHECK);
};

export const handleRunnersCheckError = ({ dispatch, commit, state }, err) => {
  commit(types.RECEIVE_RUNNERS_CHECK_ERROR, err);

  // if the config check has failed, don't worry about checking the runners again.
  if (!state.configCheck.isLoading && !state.configCheck.isValid) {
    setTimeout(() => {
      dispatch('fetchRunnersCheck', { background: true });
    }, 10000);
  }
};

export const fetchRunnersCheck = ({ dispatch, rootGetters }, options = {}) => {
  const { background = false } = options;

  if (!background) {
    dispatch('requestRunnersCheck');
  }

  const { currentProject } = rootGetters;

  axios
    .get(`/api/v4/projects/${currentProject.id}/runners`, {
      params: { scope: 'active', tag_list: WEB_IDE_JOB_TAG },
    })
    .then(({ data }) => {
      dispatch('receiveRunnersCheckSuccess', data);
    })
    .catch(e => {
      dispatch('receiveRunnersCheckError', e);
    });
};
