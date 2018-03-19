import { s__, n__ } from '~/locale';
import * as constants from './constants';
import { headSummaryTextBuilder, headBaseSummaryTextBuilder } from './utils';

export const isCIView = state => state.type === constants.CI_VIEW;
export const isMRWidget = state => state.type === constants.MR_WIDGET;

export const shouldRenderSast = state =>
  state.sast.paths.head !== null || state.sast.paths.base !== null;

export const shouldRenderSastContainer = state =>
  state.sastContainer.paths.head !== null ||
  state.sastContainer.paths.base !== null;

export const shouldRenderDast = state =>
  state.dast.paths.head !== null || state.dast.paths.base !== null;

/**
 * Return the summary text.
 * It differs between CI View and MR widget
 * @param {Object} state
 */
export const summaryText = (state, getters) => {
  if (getters.isCiView) {
    return '';
  }

  if (getters.allReportsHaveError) {
    return s__(
      'ciReport|Security scanning resulted in error when loading results',
    );
  }

  if (getters.anyReportHasError) {
    return s__(
      'ciReport|Security scanning resulted in partial error when loading results',
    );
  }

  const text = ['ciReport|Security scanning'];
  const { added, fixed } = state.summaryCounts;

  if (getters.areReportsLoading) {
    text.push('(in progress)');
  }
  if (added) {
    text.push(
      n__(
        'detected %d new vulnerability',
        'detected %d new vulnerabilities',
        added,
      ),
    );
  }
  if (added && fixed) {
    text.push('and');
  }

  if (fixed) {
    text.push(
      n__(
        'detected %d fixed vulnerability',
        'detected %d fixed vulnerabilities',
        added,
      ),
    );
  }

  return text.join(' ');
};

/**
 * @param {Object} state
 */
export const sastText = state => {
  const { newIssues, resolvedIssues, allIssues, head, base } = state.sast;

  if (head && base) {
    return headBaseSummaryTextBuilder(
      'SAST',
      newIssues.length,
      resolvedIssues.length,
      allIssues.length,
    );
  }

  return headSummaryTextBuilder('SAST', newIssues);
};

export const sastContainerText = state => {
  const {
    newIssues,
    resolvedIssues,
    head,
    base,
    unapproved,
    vulnerabilities,
    approved,
  } = state.dast;

  if (head && base) {
    return headBaseSummaryTextBuilder(
      'DAST',
      newIssues.length,
      resolvedIssues.length,
    );
  }

  if (!vulnerabilities.length) {
    return s__('ciReport|SAST:container no vulnerabilities were found');
  }

  if (!unapproved.length && approved.length) {
    return n__(
      'SAST:container found %d approved vulnerability',
      'SAST:container found %d approved vulnerabilities',
      approved.length,
    );
  } else if (unapproved.length && !approved.length) {
    return n__(
      'SAST:container found %d vulnerability',
      'SAST:container found %d vulnerabilities',
      unapproved.length,
    );
  }

  return `${n__(
    'SAST:container found %d vulnerability,',
    'SAST:container found %d vulnerabilities,',
    vulnerabilities.length,
  )} ${n__(
    'of which %d is approved',
    'of which %d are approved',
    approved.length,
  )}`;
};

export const dastText = state => {
  const { newIssues, resolvedIssues, head, base } = state.dast;

  if (head && base) {
    return headBaseSummaryTextBuilder(
      'DAST',
      newIssues.length,
      resolvedIssues.length,
    );
  }

  return headSummaryTextBuilder('DAST', newIssues);
};

export const areReportsLoading = state =>
  state.sast.isLoading || state.sastContainer.isLoading || state.dast.isLoading;

export const allReportsHaveError = state =>
  state.sast.hasError && state.sastContainer.hasError && state.dast.hasError;

export const anyReportHasError = state =>
  state.sast.hasError || state.sastContainer.hasError || state.dast.hasError;
