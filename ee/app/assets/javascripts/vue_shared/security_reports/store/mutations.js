/* eslint-disable no-param-reassign */
import * as types from './mutation_types';
import {
  parseIssues,
  filterByKey,
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
};
