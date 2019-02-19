import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import * as actions from 'ee/security_dashboard/store/modules/vulnerabilities/actions';

import mockDataVulnerabilities from './data/mock_data_vulnerabilities.json';
import mockDataVulnerabilitiesCount from './data/mock_data_vulnerabilities_count.json';
import mockDataVulnerabilitiesHistory from './data/mock_data_vulnerabilities_history.json';

import { DAYS } from 'ee/security_dashboard/store/modules/vulnerabilities/constants';

describe('vulnerabilities count actions', () => {
  const data = mockDataVulnerabilitiesCount;
  const params = { filters: { type: ['sast'] } };
  const filteredData = mockDataVulnerabilitiesCount.sast;

  describe('setVulnerabilitiesCountEndpoint', () => {
    it('should commit the correct mutuation', done => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      testAction(
        actions.setVulnerabilitiesCountEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_COUNT_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchVulnerabilitiesCount', () => {
    let mock;
    const state = initialState;

    beforeEach(() => {
      state.vulnerabilitiesCountEndpoint = `${TEST_HOST}/vulnerabilities_count.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesCountEndpoint, { params })
          .replyOnce(200, filteredData)
          .onGet(state.vulnerabilitiesCountEndpoint)
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

      it('should send the passed filters to the endpoint', done => {
        testAction(
          actions.fetchVulnerabilitiesCount,
          params,
          state,
          [],
          [
            { type: 'requestVulnerabilitiesCount' },
            {
              type: 'receiveVulnerabilitiesCountSuccess',
              payload: { data: filteredData },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.vulnerabilitiesCountEndpoint).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilitiesCount,
          {},
          state,
          [],
          [{ type: 'requestVulnerabilitiesCount' }, { type: 'receiveVulnerabilitiesCountError' }],
          done,
        );
      });
    });
  });

  describe('requestVulnerabilitiesCount', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilitiesCount,
        {},
        state,
        [{ type: types.REQUEST_VULNERABILITIES_COUNT }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesCountSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesCountSuccess,
        { data },
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS, payload: data }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesCountError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesCountError,
        {},
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_COUNT_ERROR }],
        [],
        done,
      );
    });
  });
});

describe('vulnerabilities actions', () => {
  const data = mockDataVulnerabilities;
  const params = { filters: { severity: ['critical'] } };
  const filteredData = mockDataVulnerabilities.filter(vuln => vuln.severity === 'critical');
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
      state.vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesEndpoint, { params })
          .replyOnce(200, filteredData, headers)
          .onGet(state.vulnerabilitiesEndpoint)
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

      it('should pass through the filters', done => {
        testAction(
          actions.fetchVulnerabilities,
          params,
          state,
          [],
          [
            { type: 'requestVulnerabilities' },
            {
              type: 'receiveVulnerabilitiesSuccess',
              payload: { data: filteredData, headers },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.vulnerabilitiesEndpoint).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilities,
          {},
          state,
          [],
          [{ type: 'requestVulnerabilities' }, { type: 'receiveVulnerabilitiesError' }],
          done,
        );
      });
    });
  });

  describe('receiveVulnerabilitiesSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesSuccess,
        { headers, data },
        state,
        [
          {
            type: types.RECEIVE_VULNERABILITIES_SUCCESS,
            payload: { pageInfo, vulnerabilities: data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesError,
        {},
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestVulnerabilities', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilities,
        {},
        state,
        [{ type: types.REQUEST_VULNERABILITIES }],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilitiesEndpoint', () => {
    it('should commit the correct mutuation', done => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      testAction(
        actions.setVulnerabilitiesEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
        done,
      );
    });
  });
});

describe('openModal', () => {
  it('should commit the SET_MODAL_DATA mutation', done => {
    const state = initialState;
    const vulnerability = mockDataVulnerabilities[0];

    testAction(
      actions.openModal,
      { vulnerability },
      state,
      [
        {
          type: types.SET_MODAL_DATA,
          payload: { vulnerability },
        },
      ],
      [],
      done,
    );
  });
});

describe('issue creation', () => {
  describe('createIssue', () => {
    const vulnerability = mockDataVulnerabilities[0];
    const data = { issue_url: 'fakepath.html' };
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.vulnerability_feedback_issue_path).replyOnce(200, { data });
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.createIssue,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestCreateIssue' },
            {
              type: 'receiveCreateIssueSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.vulnerability_feedback_issue_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        const flashError = false;

        testAction(
          actions.createIssue,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestCreateIssue' },
            { type: 'receiveCreateIssueError', payload: { flashError } },
          ],
          done,
        );
      });
    });
  });

  describe('receiveCreateIssueSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      testAction(
        actions.receiveCreateIssueSuccess,
        { data },
        state,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_SUCCESS,
            payload: { data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssueError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveCreateIssueError,
        {},
        state,
        [{ type: types.RECEIVE_CREATE_ISSUE_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestCreateIssue', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestCreateIssue,
        {},
        state,
        [{ type: types.REQUEST_CREATE_ISSUE }],
        [],
        done,
      );
    });
  });
});

describe('vulnerability dismissal', () => {
  describe('dismissVulnerability', () => {
    const vulnerability = mockDataVulnerabilities[0];
    const data = { vulnerability };
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.vulnerability_feedback_dismissal_path).replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.dismissVulnerability,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestDismissVulnerability' },
            {
              type: 'receiveDismissVulnerabilitySuccess',
              payload: { data, id: vulnerability.id },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.vulnerability_feedback_dismissal_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        const flashError = false;

        testAction(
          actions.dismissVulnerability,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'receiveDismissVulnerabilityError', payload: { flashError: false } },
          ],
          done,
        );
      });
    });
  });

  describe('receiveDismissVulnerabilitySuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      testAction(
        actions.receiveDismissVulnerabilitySuccess,
        { data },
        state,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS,
            payload: { data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissVulnerabilityError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveDismissVulnerabilityError,
        {},
        state,
        [{ type: types.RECEIVE_DISMISS_VULNERABILITY_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestDismissVulnerability', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestDismissVulnerability,
        {},
        state,
        [{ type: types.REQUEST_DISMISS_VULNERABILITY }],
        [],
        done,
      );
    });
  });
});

describe('revert vulnerability dismissal', () => {
  describe('undoDismiss', () => {
    const vulnerability = mockDataVulnerabilities[2];
    const url = `${vulnerability.vulnerability_feedback_dismissal_path}/${
      vulnerability.dismissal_feedback.id
    }`;
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onDelete(url).replyOnce(200, {});
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.undoDismiss,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestUndoDismiss' },
            { type: 'receiveUndoDismissSuccess', payload: { id: vulnerability.id } },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onDelete(url).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        const flashError = false;

        testAction(
          actions.undoDismiss,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestUndoDismiss' },
            { type: 'receiveUndoDismissError', payload: { flashError: false } },
          ],
          done,
        );
      });
    });
  });

  describe('receiveUndoDismissSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      testAction(
        actions.receiveUndoDismissSuccess,
        { data },
        state,
        [
          {
            type: types.RECEIVE_REVERT_DISMISSAL_SUCCESS,
            payload: { data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveUndoDismissError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveUndoDismissError,
        {},
        state,
        [{ type: types.RECEIVE_REVERT_DISMISSAL_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestUndoDismiss', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestUndoDismiss,
        {},
        state,
        [{ type: types.REQUEST_REVERT_DISMISSAL }],
        [],
        done,
      );
    });
  });
});

describe('vulnerabilities history actions', () => {
  const data = mockDataVulnerabilitiesHistory;
  const params = { filters: { severity: ['critical'] } };
  const filteredData = mockDataVulnerabilitiesHistory.critical;

  describe('setVulnerabilitiesHistoryEndpoint', () => {
    it('should commit the correct mutuation', done => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      testAction(
        actions.setVulnerabilitiesHistoryEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_HISTORY_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilitiesHistoryDayRange', () => {
    it('should commit the correct day range', done => {
      const state = initialState;
      const days = DAYS.THIRTY;
      testAction(
        actions.setVulnerabilitiesHistoryDayRange,
        days,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_HISTORY_DAY_RANGE,
            payload: days,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchVulnerabilitiesTimeline', () => {
    let mock;
    const state = initialState;

    beforeEach(() => {
      state.vulnerabilitiesHistoryEndpoint = `${TEST_HOST}/vulnerabilitIES_HISTORY.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesHistoryEndpoint, { params })
          .replyOnce(200, filteredData)
          .onGet(state.vulnerabilitiesHistoryEndpoint)
          .replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchVulnerabilitiesHistory,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilitiesHistory' },
            {
              type: 'receiveVulnerabilitiesHistorySuccess',
              payload: { data },
            },
          ],
          done,
        );
      });

      it('return the filtered results', done => {
        testAction(
          actions.fetchVulnerabilitiesHistory,
          params,
          state,
          [],
          [
            { type: 'requestVulnerabilitiesHistory' },
            {
              type: 'receiveVulnerabilitiesHistorySuccess',
              payload: { data: filteredData },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.vulnerabilitiesHistoryEndpoint).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilitiesHistory,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilitiesHistory' },
            { type: 'receiveVulnerabilitiesHistoryError' },
          ],
          done,
        );
      });
    });
  });

  describe('requestVulnerabilitiesTimeline', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilitiesHistory,
        {},
        state,
        [{ type: types.REQUEST_VULNERABILITIES_HISTORY }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesTimelineSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesHistorySuccess,
        { data },
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_HISTORY_SUCCESS, payload: data }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesTimelineError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesHistoryError,
        {},
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_HISTORY_ERROR }],
        [],
        done,
      );
    });
  });
});
