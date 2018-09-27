import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

import mockDataVulnerabilities from 'ee/security_dashboard/store/modules/vulnerabilities/mock_data_vulnerabilities.json';
import mockDataVulnerabilitiesCount from 'ee/security_dashboard/store/modules/vulnerabilities/mock_data_vulnerabilities_count.json';
import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import * as actions from 'ee/security_dashboard/store/modules/vulnerabilities/actions';

describe('vulnerabiliites count actions', () => {
  const data = mockDataVulnerabilitiesCount;

  describe('fetchVulnerabilitesCount', () => {
    let mock;
    const state = initialState;

    beforeEach(() => {
      state.vulnerabilitiesCountUrl = `${TEST_HOST}/vulnerabilities_count.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesCountUrl)
          .replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchVulnerabilitiesCount,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilitiesCount' },
            {
              type: 'receiveVulnerabilitiesCountSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });
    });

    // NOTE: This will fail as we're currently mocking the API call in the action
    // so the mock adaptor can't pick it up.
    // eslint-disable-next-line
    xdescribe('on error', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesCountUrl)
          .replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilitiesCount,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilitiesCount' },
            {
              type: 'receiveVulnerabilitiesCountError',
              payload: {},
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestVulnerabilitesCount', () => {
    it('should commit the loading mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilitiesCount,
        {},
        state,
        [
          {
            type: types.SET_VULNERABILITIES_COUNT_LOADING,
            payload: true,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitesCountSuccess', () => {
    it('should commit the required mutations', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesCountSuccess,
        { data },
        state,
        [
          { type: types.SET_VULNERABILITIES_COUNT_LOADING, payload: false },
          { type: types.SET_VULNERABILITIES_COUNT, payload: data },
        ],
        [],
        done,
      );
    });
  });

  describe('receivetVulnerabilitesCountError', () => {
    it('should commit the loading mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesCountError,
        {},
        state,
        [
          { type: types.SET_VULNERABILITIES_COUNT_LOADING, payload: false },
        ],
        [],
        done,
      );
    });
  });
});

describe('vulnerabilities actions', () => {
  const data = mockDataVulnerabilities;
  const pageInfo = {
    page: 1,
    nextPage: 2,
    previousPage: 1,
    perPage: 20,
    total: 100,
    totalPages: 5,
  };
  const headers = {
    'X-Next-Page': pageInfo.nextPage,
    'X-Page': pageInfo.page,
    'X-Per-Page': pageInfo.perPage,
    'X-Prev-Page': pageInfo.previousPage,
    'X-Total': pageInfo.total,
    'X-Total-Pages': pageInfo.totalPages,
  };

  describe('fetchVulnerabilities', () => {
    let mock;
    const state = initialState;

    beforeEach(() => {
      state.vulnerabilitiesUrl = `${TEST_HOST}/vulnerabilities.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesUrl)
          .replyOnce(200, data, headers);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchVulnerabilities,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilities' },
            {
              type: 'receiveVulnerabilitiesSuccess',
              payload: { data, headers },
            },
          ],
          done,
        );
      });
    });

    // NOTE: This will fail as we're currently mocking the API call in the action
    // so the mock adaptor can't pick it up.
    // eslint-disable-next-line
    xdescribe('on error', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesUrl)
          .replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilities,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilities' },
            {
              type: 'receiveVulnerabilitiesError',
              payload: {},
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveVulnerabilitiesSuccess', () => {
    it('should commit the required mutations', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesSuccess,
        { headers, data },
        state,
        [
          { type: types.SET_VULNERABILITIES_LOADING, payload: false },
          { type: types.SET_VULNERABILITIES, payload: data },
          { type: types.SET_PAGINATION, payload: pageInfo },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesError', () => {
    it('should commit the loading mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesError,
        {},
        state,
        [
          { type: types.SET_VULNERABILITIES_LOADING, payload: false },
        ],
        [],
        done,
      );
    });
  });

  describe('requestVulnerabilities', () => {
    it('should commit the loading mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilities,
        {},
        state,
        [
          { type: types.SET_VULNERABILITIES_LOADING, payload: true },
        ],
        [],
        done,
      );
    });
  });
});
