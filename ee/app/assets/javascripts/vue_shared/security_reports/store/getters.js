import * as constants from './constants';

/**
 * Return the summary text.
 * It differs between CI View and MR widget
 * @param {Object} state
 */
export const summaryText = (state) => {
  if (state.type === constants.CI_VIEW) {
    return '';
  }
  return '';
};

/**
 * @param {Object} state
 */
export const sastText = (state) => {
 //
};

export const sastContainerText = (state) => {

};

export const dastText = (state) => {

};

export const sastContainerInformationText = (state) => {
  // Probably not a getter
};

export const areReportsLoading = state => state.sast.isLoading ||
  state.sastContainer.isLoading ||
  state.dast.isLoading;

