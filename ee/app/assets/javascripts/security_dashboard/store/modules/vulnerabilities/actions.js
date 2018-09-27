import * as types from './mutation_types';
import mockDataVulnerabilities from './mock_data_vulnerabilities.json';
import mockDataVulnerabilitiesOverview from './mock_data_vulnerabilities_count.json';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export const fetchVulnerabilitiesCount = ({ dispatch }) => {
  dispatch('requestVulnerabilitiesCount');

  // TODO Replace with API call
  Promise.resolve({ data: mockDataVulnerabilitiesOverview })
  .then(response => {
    dispatch('receiveVulnerabilitiesCountSuccess', response);
  })
  .catch(error => {
    dispatch('receiveVulnerabilitiesCountError', error);
  });
};

export const requestVulnerabilitiesCount = ({ commit }) => {
  commit(types.SET_VULNERABILITIES_COUNT_LOADING, true);
};

export const receiveVulnerabilitiesCountSuccess = ({ commit }, response) => {
  commit(types.SET_VULNERABILITIES_COUNT_LOADING, false);
  commit(types.SET_VULNERABILITIES_COUNT, response.data);
};

export const receiveVulnerabilitiesCountError = ({ commit }) => {
  // TODO: Show error state when we get it from UX
  commit(types.SET_VULNERABILITIES_COUNT_LOADING, false);
};

export const fetchVulnerabilities = ({ dispatch }, params = {}) => {
  dispatch('requestVulnerabilities');

  // TODO: Replace with axios when we can use the actual API
  Promise.resolve({
    data: mockDataVulnerabilities,
    headers: {
      'X-Page': params.page || 1,
      'X-Next-Page': 2,
      'X-Prev-Page': 1,
      'X-Per-Page': 20,
      'X-Total': 100,
      'X-Total-Pages': 5,
    } })
    .then(response => {
      dispatch('receiveVulnerabilitiesSuccess', response);
    })
    .catch(error => {
      dispatch('receiveVulnerabilitiesError', error);
    });
};

export const requestVulnerabilities = ({ commit }) => {
  commit(types.SET_VULNERABILITIES_LOADING, true);
};

export const receiveVulnerabilitiesSuccess = ({ commit }, response = {}) => {
  const normalizedHeaders = normalizeHeaders(response.headers);
  const paginationInformation = parseIntPagination(normalizedHeaders);

  commit(types.SET_VULNERABILITIES_LOADING, false);
  commit(types.SET_VULNERABILITIES, response.data);
  commit(types.SET_PAGINATION, paginationInformation);
};

export const receiveVulnerabilitiesError = ({ commit }) => {
  // TODO: Show error state when we get it from UX
  commit(types.SET_VULNERABILITIES_LOADING, false);
};

export default () => {};
