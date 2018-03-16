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
  return '';
};

/**
 * @param {Object} state
 */
export const sastText = (state) => {

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

