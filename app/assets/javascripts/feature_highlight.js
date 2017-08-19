import Cookies from 'js-cookie';

const highlightOrder = ['issue-list', 'issue-boards'];

const mouseenter = function() {
  const $featureHighlight = $(this);
  $featureHighlight.popover('show');
  $('.popover').on('mouseleave', () => $featureHighlight.popover('hide'));
}

const mouseleave = function() {
  const $featureHighlight = $(this);
  if (!$('.popover:hover').length) {
    $featureHighlight.popover('hide');
  }
}

const dismiss = function(cookieId) {
  Cookies.set(`feature-highlighted-${cookieId}`, true);
  this.popover('hide');
  this.hide();
}

const setupDismissButton = function() {
  const popoverId = this.getAttribute('aria-describedby');
  const cookieId = this.dataset.highlight;
  const $popover = $(this);

  document.querySelector(`#${popoverId} .dismiss-feature-highlight`)
    .addEventListener('click', dismiss.bind($popover, cookieId));
}

const initFeatureHighlight = (id) => {
  const $selector = $(`.js-feature-highlight[data-highlight=${id}]`);
  const $parent = $selector.parent();
  const $popoverContent = $parent.siblings('.feature-highlight-popover-content');

  // Setup popover
  $selector.data('content', $popoverContent[0].outerHTML);
  $selector.popover({ html: true });

  $selector.on('mouseenter', mouseenter);
  $selector.on('mouseleave', mouseleave);
  $selector.on('inserted.bs.popover', setupDismissButton);

  // Display feature highlight
  $selector.removeAttr('disabled')
}

const featureHighlightManager = () => {
  highlightOrder.some((id, index) => {
    const element = document.querySelector(`.js-feature-highlight[data-highlight=${id}]`);
    const previouslyDismissed = Cookies.get(`feature-highlighted-${id}`) === 'true';
    if (element && !previouslyDismissed) {
      initFeatureHighlight(id);
      return true;
    }

    return false;
  });
};

featureHighlightManager();

export default featureHighlightManager;
