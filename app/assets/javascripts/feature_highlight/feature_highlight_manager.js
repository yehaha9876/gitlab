import Cookies from 'js-cookie';
import {
  getCookieName,
  getSelector,
  setupDismissButton,
  mouseenter,
  mouseleave,
} from './feature_highlight';

export default class FeatureHighlightManager {
  constructor(highlightOrder) {
    this.highlightOrder = highlightOrder;
  }

  init() {
    const featureId = this.highlightOrder.find(FeatureHighlightManager.shouldHighlightFeature);

    if (featureId) {
      FeatureHighlightManager.highlightFeature(featureId);
      window.addEventListener('scroll', () => {
        const $featureHighlight = $(getSelector(featureId));
        $featureHighlight.popover('hide');
      });
    }
  }

  static shouldHighlightFeature(id) {
    const element = document.querySelector(getSelector(id));
    const previouslyDismissed = Cookies.get(getCookieName(id)) === 'true';

    return element && !previouslyDismissed;
  }

  static highlightFeature(id) {
    const $selector = $(getSelector(id));
    const $parent = $selector.parent();
    const $popoverContent = $parent.siblings('.feature-highlight-popover-content');

    // Setup popover
    $selector.data('content', $popoverContent[0].outerHTML);
    $selector.popover({
      html: true,
      // Override the existing template to add custom CSS classes
      template: `
        <div class="popover feature-highlight-popover" role="tooltip">
          <div class="arrow"></div>
          <div class="popover-content"></div>
        </div>
      `,
    });

    $selector.on('mouseenter', mouseenter);
    $selector.on('mouseleave', mouseleave);
    $selector.on('inserted.bs.popover', setupDismissButton);

    // Display feature highlight
    $selector.removeAttr('disabled');
  }
}
