import * as types from './mutation_types';

export default {
  [types.SET_PAGINATION](state, payload) {
    state.pageInfo = payload;
  },
  [types.SET_VULNERABILITIES](state, payload) {
    state.vulnerabilities = payload;
  },
  [types.SET_VULNERABILITIES_LOADING](state, payload) {
    state.loadingVulnerabilities = payload;
  },
  [types.SET_VULNERABILITIES_COUNT](state, payload) {
    state.vulnerabilitiesCount = payload;
  },
  [types.SET_VULNERABILITIES_COUNT_LOADING](state, payload) {
    state.loadingVulnerabilitiesCount = payload;
  },
};
