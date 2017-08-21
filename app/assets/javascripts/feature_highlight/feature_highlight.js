import Cookies from 'js-cookie';

export const getCookieName = cookieId => `feature-highlighted-${cookieId}`;
export const getSelector = highlightId => `.js-feature-highlight[data-highlight=${highlightId}]`;

const dismiss = function dismiss(cookieId) {
  Cookies.set(getCookieName(cookieId), true);
  this.popover('hide');
  this.hide();
};

export const mouseenter = function mouseenter() {
  const $featureHighlight = $(this);
  $featureHighlight.popover('show');

  document.querySelector('.popover')
    .addEventListener('mouseleave', () => $featureHighlight.popover('hide'));
};

export const mouseleave = function mouseleave() {
  if (!document.querySelector('.popover:hover')) {
    const $featureHighlight = $(this);
    $featureHighlight.popover('hide');
  }
};

export const setupDismissButton = function setupDismissButton() {
  const popoverId = this.getAttribute('aria-describedby');
  const cookieId = this.dataset.highlight;
  const $popover = $(this);

  document.querySelector(`#${popoverId} .dismiss-feature-highlight`)
    .addEventListener('click', dismiss.bind($popover, cookieId));
};
