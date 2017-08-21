import FeatureHighlightManager from './feature_highlight_manager';

const highlightOrder = ['issue-boards'];

document.addEventListener('DOMContentLoaded', () => {
  const featureHighlight = new FeatureHighlightManager(highlightOrder);
  featureHighlight.init();
});
