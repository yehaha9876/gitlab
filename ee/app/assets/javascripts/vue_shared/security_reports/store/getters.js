import { s__, n__, __ } from '~/locale';
import * as constants from './constants';

export const isCIView = (state) => state.type === constants.CI_VIEW;
export const isMRWidget = (state) => state.type === constants.MR_WIDGET;

export const shouldRenderSast = (state) =>
  state.sast.paths.head !== null ||
  state.sast.paths.base !== null;

export const shouldRenderSastContainer = (state) =>
  state.sastContainer.paths.head !== null ||
  state.sastContainer.paths.base !== null;

export const shouldRenderDast = (state) =>
  state.dast.paths.head !== null ||
  state.dast.paths.base !== null;

  /**
 * Return the summary text.
 * It differs between CI View and MR widget
 * @param {Object} state
 */
export const summaryText = (state, getters) => {
  if (getters.isCiView) {
    return '';
  }

  if (getters.hasError) {
    return s__('Security scanning resulted in error when loading results');
  }

  const text = ['ciReport|Security scanning'];
  const { added, fixed } = state.summaryCounts;

  if (getters.areReportsLoading) {
    text.push('(in progress)');
  }
  if (added) {
    text.push(n__(
      'detected %d new vulnerability',
      'detected %d new vulnerabilities',
      added,
    ));
  }
  if (added && fixed) {
    text.push('and');
  }

  if (fixed) {
    text.push(n__(
      'detected %d fixed vulnerability',
      'detected %d fixed vulnerabilities',
      added,
    ));
  }
  return text.join(' ');
};

/**
 * @param {Object} state
 */
export const sastText = (state, getters) => {
  const { newIssues, resolvedIssues, allIssues } = state.sast;
  const text = [];

  if (getters.isMRWidget) {
    if (!newIssues.length && !resolvedIssues.length && !allIssues.length) {
      text.push(s__('ciReport|SAST detected no security vulnerabilities'));
    } else if (!newIssues.length && !resolvedIssues.length && allIssues.length) {
      text.push(s__('ciReport|SAST detected no new security vulnerabilities'));
    } else if (newIssues.length || resolvedIssues.length) {
      text.push(s__('ciReport|SAST'));
    }

    if (resolvedIssues.length) {
      text.push(n__(
        'detected %d new vulnerability',
        'detected %d new vulnerabilities',
        resolvedIssues.length,
      ));
    }

    if (newIssues.length > 0 && resolvedIssues.length > 0) {
      text.push(__('and'));
    }

    if (newIssues.length) {
      text.push(n__(
        'detected %d fixed vulnerability',
        'detected %d fixed vulnerabilities',
        newIssues.length,
      ));
    }
    return text.join(' ');
  }

  if (getters.isCiView) {
    if (!newIssues.length) {
      return s__('ciReport|SAST detected no security vulnerabilities');
    }

    return n__(
      'SAST detected %d vulnerability',
      'SAST detected %d vulnerabilities',
      resolvedIssues.length,
    );
  }
  return '';
};

export const sastContainerText = (state) => {

};

export const dastText = (state) => {

};

export const sastContainerInformationText = (state) => {
  // Probably not be a getter
};

export const areReportsLoading = state => state.sast.isLoading ||
  state.sastContainer.isLoading ||
  state.dast.isLoading;

