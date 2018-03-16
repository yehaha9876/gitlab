import { stripHtml } from '~/lib/utils/text_utility';
import * as types from './mutation_types';
import {
  parseIssues,
  filterByKey,
  parseSastContainer,
} from '../helpers/utils';

export default {
  [types.SET_HEAD_BLOB_PATH](state, path) {
    Object.assign(state.blobPath, { head: path });
  },

  [types.SET_BASE_BLOB_PATH](state, path) {
    Object.assign(state.blobPath, { base: path });
  },

  [types.INCREMENT_SUMMARY_NEW_COUNT](state, count) {
    Object.assign(state.summaryCounts, { new: state.summaryCounts.new + count });
  },

  [types.INCREMENT_SUMMARY_FIXED_COUNT](state, count) {
    Object.assign(state.summaryCounts, { fixed: state.summaryCounts.fixed + count });
  },

  // SAST

  [types.SET_SAST_HEAD_PATH](state, path) {
    Object.assign(state.sast.paths, { head: path });
  },

  [types.SET_SAST_BASE_PATH](state, path) {
    Object.assign(state.sast.paths, { base: path });
  },

  [types.REQUEST_SAST_REPORTS](state) {
    Object.assign(state.sast, { isLoading: true });
  },

  [types.RECEIVE_SAST_REPORTS](state, reports) {
    if (reports.base && reports.head) {
      const filterKey = 'cve';
      const parsedHead = parseIssues(reports.head, state.blobPath.head);
      const parsedBase = parseIssues(reports.base, state.blobPath.base);

      const newIssues = filterByKey(parsedHead, parsedBase, filterKey);
      const fixedIssues = filterByKey(parsedBase, parsedHead, filterKey);
      const allIssues = filterByKey(parsedHead, newIssues.concat(fixedIssues), filterKey);

      Object.assign(state.sast, {
        newIssues,
        fixedIssues,
        allIssues,
        isLoading: false,
      });
    } else {
      Object.assign(state.sast, {
        newIssues: parseIssues(reports.head, state.blobPath.head),
        isLoading: false,
      });
    }
  },

  [types.RECEIVE_SAST_REPORTS_ERROR](state) {
    Object.assign(state.sast, {
      isLoading: false,
      hasError: true,
    });
  },

  // SAST CONTAINER

  [types.SET_SAST_CONTAINER_HEAD_PATH](state, path) {
    Object.assign(state.sastContainer.paths, { head: path });
  },

  [types.SET_SAST_CONTAINER_BASE_PATH](state, path) {
    Object.assign(state.sastContainer.paths, { base: path });
  },

  [types.REQUEST_SAST_CONTAINER_REPORTS](state) {
    Object.assign(state.sastContainer, { isLoading: true });
  },

  [types.RECEIVE_SAST_CONTAINER_REPORTS](state, reports) {
    if (reports.base && reports.head) {
      // TODO set when we receive head+base
    } else {
      const parsedVulnerabilities = parseSastContainer(reports.head.vulnerabilities);
      const unapproved = reports.head.unapproved || [];

      Object.assign(state.sastContainer, {
        isLoading: false,
        vulnerabilities: parsedVulnerabilities || [],
        approved: parsedVulnerabilities
          .filter(item => !unapproved.find(el => el === item.vulnerability)) || [],
        unapproved: parsedVulnerabilities
          .filter(item => unapproved.find(el => el === item.vulnerability)) || [],
      });
    }
  },

  [types.RECEIVE_SAST_CONTAINER_ERROR](state) {
    Object.assign(state.sastContainer, {
      isLoading: false,
      hasError: true,
    });
  },

  // DAST

  [types.SET_DAST_HEAD_PATH](state, path) {
    Object.assign(state.dast.paths, { head: path });
  },

  [types.SET_DAST_BASE_PATH](state, path) {
    Object.assign(state.dast.paths, { base: path });
  },

  [types.REQUEST_DAST_REPORTS](state) {
    Object.assign(state.dast, { isLoading: true });
  },

  [types.RECEIVE_DAST_REPORTS](state, reports) {
    if (reports.head && reports.base) {
      // TODO set when we receive head.base
    } else {
      const alerts = reports.head.site.alerts;

      Object.assign(state.dast, {
        isLoading: false,
        newIssues: alerts.map(alert => ({
          name: alert.name,
          parsedDescription: stripHtml(alert.desc, ' '),
          priority: alert.riskdesc,
          ...alert,
        })),
      });
    }
  },

  [types.RECEIVE_DAST_ERROR](state) {
    Object.assign(state.dast, {
      isLoading: false,
      hasError: true,
    });
  },
};
