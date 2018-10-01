import * as types from './mutation_types';
import {
  STATUS_STARTING,
} from '../../../constants';

export default {
  [types.SET_ENABLED](state, isEnabled) {
    Object.assign(state, {
      isEnabled,
    });
  },
  [types.HIDE_SPLASH](state) {
    Object.assign(state, {
      isShowSplash: false,
    });
  },
  [types.SET_PATHS](state, paths) {
    Object.assign(state, {
      paths,
    });
  },
  [types.REQUEST_CONFIG_CHECK](state) {
    Object.assign(state, {
      configCheck: {
        isLoading: true,
      },
    });
  },
  [types.RECEIVE_CONFIG_CHECK_ERROR](state, message) {
    Object.assign(state, {
      configCheck: {
        isLoading: false,
        isValid: false,
        message,
      },
    });
  },
  [types.RECEIVE_CONFIG_CHECK_SUCCESS](state) {
    Object.assign(state, {
      configCheck: {
        isLoading: false,
        isValid: true,
        message: null,
      },
    });
  },
  [types.REQUEST_RUNNERS_CHECK](state) {
    Object.assign(state, {
      runnersCheck: {
        isLoading: true,
      },
    });
  },
  [types.RECEIVE_RUNNERS_CHECK_ERROR](state, message) {
    Object.assign(state, {
      runnersCheck: {
        isLoading: false,
        isValid: false,
        message,
      },
    });
  },
  [types.RECEIVE_RUNNERS_CHECK_SUCCESS](state) {
    Object.assign(state, {
      runnersCheck: {
        isLoading: false,
        isValid: true,
        message: null,
      },
    });
  },
  [types.START_SESSION](state, { sessionPath }) {
    Object.assign(state, {
      sessionStatus: STATUS_STARTING,
      sessionPath,
    });
  },
  [types.SET_SESSION_STATUS](state, sessionStatus) {
    Object.assign(state, {
      sessionStatus,
    });
  },
  [types.SET_SESSION_STATUS_INTERVAL](state, sessionStatusInterval) {
    Object.assign(state, {
      sessionStatusInterval,
    });
  },
};
