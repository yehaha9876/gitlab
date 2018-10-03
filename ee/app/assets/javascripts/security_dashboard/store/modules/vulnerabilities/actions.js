import $ from 'jquery';
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
  commit(types.REQUEST_VULNERABILITIES_COUNT);
};

export const receiveVulnerabilitiesCountSuccess = ({ commit }, response) => {
  commit(types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS, response.data);
};

export const receiveVulnerabilitiesCountError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_COUNT_ERROR);
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
  commit(types.REQUEST_VULNERABILITIES);
};

export const receiveVulnerabilitiesSuccess = ({ commit }, response = {}) => {
  const normalizedHeaders = normalizeHeaders(response.headers);
  const pageInfo = parseIntPagination(normalizedHeaders);
  const vulnerabilities = response.data;

  commit(types.RECEIVE_VULNERABILITIES_SUCCESS, { pageInfo, vulnerabilities });
};

export const receiveVulnerabilitiesError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_ERROR);
};

export const openModal = ({ commit }, vulnerability = {}) => {
  commit(types.SET_MODAL_DATA, vulnerability);

  $('#modal-mrwidget-security-issue').modal('show');
};

export default () => {};
